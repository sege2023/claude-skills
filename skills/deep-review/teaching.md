# Learn mode

Goal: build the user's own review intuition. Teach the reasoning, not only the results. Run the same passes as the standard review, but in this order and with these pauses.

1. **Intent first, from the user.** Ask the user to state in one sentence what the change should do. Compare it with your own reading. A mismatch is worth discussing before anything else.

2. **Change map.** Show it, then point out the single interface change that matters most and why: who calls it, and what breaks if a caller was missed.

3. **Trace walkthrough.** Walk one entry point step by step with a mermaid `sequenceDiagram`. At each step, name the question a reviewer asks there and which lens it comes from, e.g. "step 3 takes a list: boundaries lens, what if it's empty?"

4. **Predict before reveal.** Before showing any findings, ask one or two questions that point at the riskiest area without giving the answer, e.g. "Look at steps 3 to 5. What happens if the websocket drops between sending the order and receiving the ack?" Wait for the reply.

5. **Reveal.** Give the findings in the standard format, each with its "Found via" line. Compare them with the user's prediction: name what they caught, what they missed, and which lens would have surfaced it.

6. **One takeaway.** End with a single reusable heuristic from this review, phrased as a rule they can apply next time, e.g. "When a function returns None on failure, check that every caller handles None."

## Style

- Never quiz on syntax, definitions or library trivia. Ask about behavior in production.
- At most two questions before the reveal.
- When a concept is new to the user, explain it by mapping it to something they already know. Ask what they know if unsure.
- When a formula appears, define every parameter and give a minimal worked example with real numbers.
