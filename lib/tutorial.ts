import type { Action, Word } from './engine.ts'

export interface TutorialPuzzle {
  title: string
  text: string
  start: Action[]
  visible: 'all' | Word[]
  buttons: Action[]
  discs_pole?: Word
  goal: Record<Word, number>
  solution: number[]
  after: string
  highlight?: Word[]
  notes?: string
}

export interface TutorialChapter {
  title: string
  concept: string
  puzzles: TutorialPuzzle[]
}

export interface Tutorial {
  title: string
  intro: string
  chapters: TutorialChapter[]
}

export interface FlatPuzzle {
  chapter: TutorialChapter
  puzzle: TutorialPuzzle
}

export const GOAL_TOL = 0.05

export function flatten(data: Tutorial): FlatPuzzle[] {
  return data.chapters.flatMap((chapter) => chapter.puzzles.map((puzzle) => ({ chapter, puzzle })))
}
