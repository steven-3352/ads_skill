#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const CHANNELS = new Set([
  'picture',
  'dialogue',
  'action_sound',
  'ambience',
  'transition',
  'onscreen_text',
]);

const fail = (message) => {
  process.stderr.write(`production-plan: ${message}\n`);
  process.exitCode = 1;
};

const isText = (value) => typeof value === 'string' && value.trim().length > 0;
const asArray = (value) => Array.isArray(value) ? value : [];
const closeEnough = (a, b) => Math.abs(a - b) < 0.001;

function parseArgs(argv) {
  const args = [...argv];
  const planFile = args.shift();
  let projectRoot;
  while (args.length) {
    const arg = args.shift();
    if (arg === '--project-root') projectRoot = args.shift();
    else throw new Error(`unknown argument: ${arg}`);
  }
  if (!planFile) throw new Error('usage: validate-production-plan.mjs <plan.json> [--project-root <dir>]');
  return {
    planFile: path.resolve(planFile),
    projectRoot: path.resolve(projectRoot ?? path.dirname(path.resolve(planFile))),
  };
}

function addUnique(seen, value, label, problems) {
  if (!isText(value)) {
    problems.push(`${label} must be a non-empty string`);
    return false;
  }
  if (seen.has(value)) {
    problems.push(`${label} is duplicated: ${value}`);
    return false;
  }
  seen.add(value);
  return true;
}

function checkRelativePath(value, prefix, label, problems, nullable = false) {
  if (nullable && (value === null || value === undefined || value === '')) return;
  if (!isText(value)) {
    problems.push(`${label} must be a non-empty relative path`);
    return;
  }
  if (path.isAbsolute(value) || value.split(/[\\/]/).includes('..')) {
    problems.push(`${label} must stay inside the project: ${value}`);
  } else if (!value.startsWith(prefix)) {
    problems.push(`${label} must start with ${prefix}: ${value}`);
  }
}

function validateCoverage(items, owner, beats, claims, problems) {
  for (const item of asArray(items)) {
    if (!isText(item?.beatId) || !beats.has(item.beatId)) {
      problems.push(`${owner} references unknown beat: ${item?.beatId ?? '<missing>'}`);
      continue;
    }
    const channels = asArray(item.channels);
    if (!channels.length) problems.push(`${owner} coverage for ${item.beatId} has no channels`);
    for (const channel of channels) {
      if (!CHANNELS.has(channel)) {
        problems.push(`${owner} uses unsupported channel ${channel} for ${item.beatId}`);
        continue;
      }
      const key = `${item.beatId}:${channel}`;
      const owners = claims.get(key) ?? [];
      owners.push(owner);
      claims.set(key, owners);
    }
  }
}

export function validateProductionPlan(doc, options = {}) {
  const problems = [];
  const projectRoot = path.resolve(options.projectRoot ?? '.');

  if (doc?.schemaVersion !== 1) problems.push('schemaVersion must equal 1');
  if (!isText(doc?.projectId)) problems.push('projectId must be a non-empty string');
  const modelSkills = {
    'MiniMax-H3': { skill: 'h3-prompt-writing', gate: 'replication/tools/validate-h3-prompt-review.sh' },
    'Seedance-2.0': { skill: 'seedance-prompt-zh', gate: 'replication/tools/validate-seedance-prompt-review.sh' },
  };
  const model = doc?.promptPolicy?.model;
  if (!Object.hasOwn(modelSkills, model)) {
    problems.push('promptPolicy.model must be MiniMax-H3 or Seedance-2.0');
  } else {
    const policy = modelSkills[model];
    if (doc?.promptPolicy?.authoringSkill !== policy.skill) {
      problems.push(`promptPolicy.authoringSkill must be ${policy.skill} for ${model}`);
    }
    if (doc?.promptPolicy?.reviewGate !== policy.gate) {
      problems.push(`promptPolicy.reviewGate must be ${policy.gate} for ${model}`);
    }
  }

  const maxGenerationSeconds = doc?.constraints?.maxGenerationSeconds ?? 15;
  if (!(Number.isFinite(maxGenerationSeconds) && maxGenerationSeconds > 0)) {
    problems.push('constraints.maxGenerationSeconds must be a positive number');
  }

  const shots = asArray(doc?.narrativeShots);
  if (!shots.length) problems.push('narrativeShots must contain at least one shot');
  const shotIds = new Set();

  for (const shot of shots) {
    const shotLabel = `narrativeShot ${shot?.id ?? '<missing>'}`;
    addUnique(shotIds, shot?.id, 'narrativeShot.id', problems);
    if (!isText(shot?.title)) problems.push(`${shotLabel}.title must be non-empty`);
    if (!isText(shot?.source?.verbatim)) problems.push(`${shotLabel}.source.verbatim must be non-empty`);

    if (isText(shot?.source?.storyFile)) {
      const sourcePath = path.resolve(projectRoot, shot.source.storyFile);
      if (!sourcePath.startsWith(`${projectRoot}${path.sep}`) && sourcePath !== projectRoot) {
        problems.push(`${shotLabel}.source.storyFile escapes the project root`);
      } else if (fs.existsSync(sourcePath)) {
        const sourceText = fs.readFileSync(sourcePath, 'utf8');
        if (isText(shot?.source?.verbatim) && !sourceText.includes(shot.source.verbatim)) {
          problems.push(`${shotLabel}.source.verbatim does not match ${shot.source.storyFile}`);
        }
      }
    }

    const beats = new Map();
    const required = new Set();
    for (const beat of asArray(shot?.requiredBeats)) {
      if (!addUnique(new Set(beats.keys()), beat?.id, `${shotLabel}.requiredBeat.id`, problems)) continue;
      beats.set(beat.id, beat);
      if (!isText(beat?.sceneId)) problems.push(`${shotLabel}.${beat.id}.sceneId must be non-empty`);
      if (!isText(beat?.text)) problems.push(`${shotLabel}.${beat.id}.text must be non-empty`);
      const channels = asArray(beat?.channels);
      if (!channels.length) problems.push(`${shotLabel}.${beat.id}.channels must not be empty`);
      const localChannels = new Set();
      for (const channel of channels) {
        if (!CHANNELS.has(channel)) problems.push(`${shotLabel}.${beat.id} has unsupported channel ${channel}`);
        if (localChannels.has(channel)) problems.push(`${shotLabel}.${beat.id} repeats channel ${channel}`);
        localChannels.add(channel);
        required.add(`${beat.id}:${channel}`);
      }
    }
    if (!beats.size) problems.push(`${shotLabel}.requiredBeats must not be empty`);

    const claims = new Map();
    const unitIds = new Set();
    for (const unit of asArray(shot?.generationUnits)) {
      const unitLabel = `${shotLabel}.generationUnit ${unit?.id ?? '<missing>'}`;
      addUnique(unitIds, unit?.id, `${shotLabel}.generationUnit.id`, problems);
      if (!isText(unit?.sceneId)) problems.push(`${unitLabel}.sceneId must be non-empty`);
      if (!(Number.isFinite(unit?.durationSeconds) && unit.durationSeconds > 0)) {
        problems.push(`${unitLabel}.durationSeconds must be positive`);
      } else if (unit.durationSeconds > maxGenerationSeconds) {
        problems.push(`${unitLabel} is ${unit.durationSeconds}s, above maxGenerationSeconds ${maxGenerationSeconds}s`);
      }

      const cuts = asArray(unit?.cuts);
      if (!cuts.length) problems.push(`${unitLabel}.cuts must not be empty`);
      const cutIds = new Set();
      let cutSeconds = 0;
      for (const cut of cuts) {
        const cutLabel = `${unitLabel}.cut ${cut?.id ?? '<missing>'}`;
        addUnique(cutIds, cut?.id, `${unitLabel}.cut.id`, problems);
        if (!(Number.isFinite(cut?.seconds) && cut.seconds > 0)) problems.push(`${cutLabel}.seconds must be positive`);
        else cutSeconds += cut.seconds;
        validateCoverage(cut?.coverage, cutLabel, beats, claims, problems);
        for (const item of asArray(cut?.coverage)) {
          const beat = beats.get(item?.beatId);
          if (beat && unit?.sceneId !== beat.sceneId) {
            problems.push(`${cutLabel} crosses scenes: unit ${unit?.sceneId}, beat ${beat.sceneId}`);
          }
        }
      }
      if (Number.isFinite(unit?.durationSeconds) && !closeEnough(cutSeconds, unit.durationSeconds)) {
        problems.push(`${unitLabel} cut seconds ${cutSeconds} do not equal durationSeconds ${unit.durationSeconds}`);
      }

      for (const prompt of asArray(unit?.prompts?.images)) {
        checkRelativePath(prompt, 'prompts/', `${unitLabel}.prompts.images[]`, problems);
      }
      checkRelativePath(unit?.prompts?.video, 'prompts/', `${unitLabel}.prompts.video`, problems, true);
      const shotDir = `shots/shot-${shot.id}/`;
      checkRelativePath(unit?.media?.firstFrame, `${shotDir}images/`, `${unitLabel}.media.firstFrame`, problems, true);
      checkRelativePath(unit?.media?.lastFrame, `${shotDir}images/`, `${unitLabel}.media.lastFrame`, problems, true);
      checkRelativePath(unit?.media?.video, `${shotDir}video/`, `${unitLabel}.media.video`, problems, true);
      for (const reference of asArray(unit?.references)) {
        if (!isText(reference) || path.isAbsolute(reference) || reference.split(/[\\/]/).includes('..')) {
          problems.push(`${unitLabel}.references[] must stay inside the project: ${reference}`);
        } else if (!(reference.startsWith('assets/') || reference.startsWith(shotDir))) {
          problems.push(`${unitLabel}.references[] must use assets/ or the current ${shotDir}: ${reference}`);
        }
      }
    }
    if (!asArray(shot?.generationUnits).length) problems.push(`${shotLabel}.generationUnits must not be empty`);

    const taskIds = new Set();
    for (const task of asArray(shot?.postTasks)) {
      const taskLabel = `${shotLabel}.postTask ${task?.id ?? '<missing>'}`;
      addUnique(taskIds, task?.id, `${shotLabel}.postTask.id`, problems);
      if (!isText(task?.type)) problems.push(`${taskLabel}.type must be non-empty`);
      if (!isText(task?.description)) problems.push(`${taskLabel}.description must be non-empty`);
      validateCoverage(task?.coverage, taskLabel, beats, claims, problems);
    }

    for (const key of required) {
      const owners = claims.get(key) ?? [];
      if (!owners.length) problems.push(`${shotLabel} leaves required coverage unclaimed: ${key}`);
      else if (owners.length > 1) problems.push(`${shotLabel} claims required coverage more than once: ${key} by ${owners.join(', ')}`);
    }
    for (const key of claims.keys()) {
      if (!required.has(key)) problems.push(`${shotLabel} claims a channel that is not required: ${key}`);
    }
  }

  return problems;
}

function main() {
  let options;
  try {
    options = parseArgs(process.argv.slice(2));
  } catch (error) {
    fail(error.message);
    return;
  }

  let doc;
  try {
    doc = JSON.parse(fs.readFileSync(options.planFile, 'utf8'));
  } catch (error) {
    fail(`cannot read ${options.planFile}: ${error.message}`);
    return;
  }

  const problems = validateProductionPlan(doc, options);
  if (problems.length) {
    for (const problem of problems) fail(problem);
    return;
  }
  process.stdout.write(`production-plan: valid (${doc.narrativeShots.length} narrative shots)\n`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname)) main();
