#!/usr/bin/env node

import assert from 'node:assert/strict';
import { validateProductionPlan } from './validate-production-plan.mjs';

const valid = {
  schemaVersion: 1,
  projectId: 'test-project',
  promptPolicy: {
    model: 'Seedance-2.0',
    authoringSkill: 'seedance-prompt-zh',
    reviewGate: 'replication/tools/validate-seedance-prompt-review.sh',
  },
  constraints: { maxGenerationSeconds: 15 },
  narrativeShots: [{
    id: '01',
    title: '夹虾与回望',
    source: { verbatim: '小周夹来一只虾。林晚夹回去，听见虾壳脆响后抬眼。' },
    requiredBeats: [
      { id: '01-b01', sceneId: 'scene-01', text: '小周夹虾', channels: ['picture'] },
      { id: '01-b02', sceneId: 'scene-01', text: '林晚夹回', channels: ['picture'] },
      { id: '01-b03', sceneId: 'scene-01', text: '脆响引发回忆', channels: ['action_sound', 'transition'] },
    ],
    generationUnits: [{
      id: '01A',
      sceneId: 'scene-01',
      durationSeconds: 12,
      cuts: [
        { id: '01A-c01', seconds: 5, coverage: [{ beatId: '01-b01', channels: ['picture'] }] },
        { id: '01A-c02', seconds: 7, coverage: [{ beatId: '01-b02', channels: ['picture'] }] },
      ],
      prompts: {
        images: ['prompts/01-shot-01a-first-frame.json'],
        video: 'prompts/01-shot-01a-video.json',
      },
      media: {
        firstFrame: 'shots/shot-01/images/01a-first-frame.png',
        video: 'shots/shot-01/video/01a.mp4',
      },
      references: ['assets/lin-wan-master.png'],
    }],
    postTasks: [{
      id: '01-post-bridge',
      type: 'sound_bridge',
      description: '虾壳脆响接下一段回忆',
      coverage: [{ beatId: '01-b03', channels: ['action_sound', 'transition'] }],
    }],
  }],
};

assert.deepEqual(validateProductionPlan(valid), []);

const missing = structuredClone(valid);
missing.narrativeShots[0].postTasks = [];
assert(validateProductionPlan(missing).some((problem) => problem.includes('01-b03:transition')));

const duplicate = structuredClone(valid);
duplicate.narrativeShots[0].postTasks.push({
  id: '01-post-duplicate',
  type: 'transition',
  description: '重复认领转场',
  coverage: [{ beatId: '01-b03', channels: ['transition'] }],
});
assert(validateProductionPlan(duplicate).some((problem) => problem.includes('more than once')));

const wrongSkill = structuredClone(valid);
wrongSkill.promptPolicy.authoringSkill = 'novel-storyboard';
assert(validateProductionPlan(wrongSkill).some((problem) => problem.includes('seedance-prompt-zh')));

const h3 = structuredClone(valid);
h3.promptPolicy.model = 'MiniMax-H3';
h3.promptPolicy.authoringSkill = 'h3-prompt-writing';
h3.promptPolicy.reviewGate = 'replication/tools/validate-h3-prompt-review.sh';
assert.deepEqual(validateProductionPlan(h3), []);

const missingModel = structuredClone(valid);
delete missingModel.promptPolicy.model;
assert(validateProductionPlan(missingModel).some((problem) => problem.includes('promptPolicy.model')));

const tooLong = structuredClone(valid);
tooLong.narrativeShots[0].generationUnits[0].durationSeconds = 16;
tooLong.narrativeShots[0].generationUnits[0].cuts[1].seconds = 11;
assert(validateProductionPlan(tooLong).some((problem) => problem.includes('above maxGenerationSeconds')));

const foreignShotAsset = structuredClone(valid);
foreignShotAsset.narrativeShots[0].generationUnits[0].references.push('shots/shot-02/images/frame.png');
assert(validateProductionPlan(foreignShotAsset).some((problem) => problem.includes('current shots/shot-01/')));

process.stdout.write('production-plan selftest: passed\n');
