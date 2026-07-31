---
name: pelizzai-writing-clearly-and-concisely
description: A skill that applies William Strunk Jr.'s timeless writing principles to produce clearer, more vigorous, professional prose while avoiding common AI writing patterns.
---

# Writing Clearly and Concisely

## Overview

Write with clarity and force. This skill covers what to do (Strunk) and what not to do (AI patterns).

## When to Use This Skill

Use this skill whenever you write text for humans:

- Documentation, README files, technical explanations
- Commit messages, pull request descriptions
- Error messages, UI text, help text, comments
- Reports, summaries, or any kind of explanation
- Editing for clarity

**If you are writing sentences for a human to read, use this skill.**

## Strategy for Limited Context

When context is tight:

1. Write your draft using your own judgment
2. Launch a subagent with your draft and the relevant section file
3. Ask the subagent to review the text and return the corrected version

Loading a single section (~1,350 to ~11,800 tokens depending on the section; file `03` is the largest) instead of everything saves a significant amount of context.

## Elements of Style

William Strunk Jr.'s _The Elements of Style_ (1918) teaches how to write clearly and cut the superfluous without mercy.

### Rules

**Elementary Rules of Usage (Grammar/Punctuation)**:

1. Form the possessive singular of nouns by adding _'s_
2. In a series of three or more terms with a single conjunction, use a comma after each term except the last (the serial comma)
3. Enclose parenthetic (incidental) expressions between commas
4. Place a comma before a conjunction introducing a co-ordinate clause
5. Do not join independent clauses with only a comma
6. Do not break sentences in two
7. A participial phrase at the beginning of a sentence must refer to the grammatical subject

**Elementary Principles of Composition**:

8. One paragraph per topic
9. Begin each paragraph with a sentence that states the main topic
10. **Use the active voice**
11. **Put statements in positive form**
12. **Use definite, specific, concrete language**
13. **Omit needless words**
14. Avoid a succession of loose sentences (with no clear connection)
15. Express co-ordinate ideas in similar form
16. **Keep related words together**
17. In summaries, keep to one tense
18. **Place the emphatic words at the end of the sentence**

### Reference Files

The rules above summarize Strunk's original text. For full explanations with examples:

| Section | File | ~Tokens |
| --- | --- | --- |
| Grammar, punctuation, comma usage | `02-elementary-rules-of-usage.md` | ~3,900 |
| Paragraphs, active voice, concision | `03-elementary-principles-of-composition.md` | ~11,800 |
| Headings, quotations, formatting | `04-a-few-matters-of-form.md` | ~1,350 |
| Word choice (crutch words and commonly confused pairs) | `05-words-and-expressions-commonly-misused.md` | ~1,800 |

**Most tasks need only `03-elementary-principles-of-composition.md`** — it covers active voice, positive form, concrete language, and the elimination of needless words.

## AI Writing Patterns to Avoid

LLMs tend to converge on statistical averages, producing generic, inflated prose. Avoid:

- **Inflated terms:** pivotal, crucial, vital, testament, enduring legacy
- **Empty -ing phrases:** ensuring reliability, showcasing features, highlighting capabilities
- **Promotional adjectives:** revolutionary, seamless, robust, cutting-edge
- **Overused AI vocabulary:** delve, leverage, multifaceted, foster, realm, tapestry
- **Formatting excess:** too many bulleted lists, emoji decoration, mechanical bolding of repeated key terms

Be specific, not grandiose. Say what it actually does.

For detailed research on why these patterns occur, see `signs-of-ai-writing.md`. Wikipedia editors developed that guide to detect AI-generated submissions — its patterns are well documented and field-tested.

## Summary

Writing for humans? Load the relevant section of `elements-of-style/` and apply the rules. For most tasks, `03-elementary-principles-of-composition.md` covers what matters most.
