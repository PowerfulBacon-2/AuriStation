
## Injuries

Merge the no blood trait and the blood/none datums. If we have both, then we need to make sure that one cannot exist without the other otherwise we will have issues.
Rework security, ballistic security will never work under injuries and they can't be given ballistic weapons.
Test organs such as weapon implants to make sure they can only be put in the correct slots.
Heart attack has no effect on blood circulation
Self examination shows no injuries even when injured.
When falling down you need to move before you attempt to stand
You should always be unconscious when you start to see the white light at the edge of the screen.
Someone with fully healed brute and almost fully healed hypoxia still had 170% pain stimulation. (Pain variable on pain_source was null/15, adjusted pain was 170 but was moving). This is probably beacuse the max pain recovery rate is 0.2 per second which if you reach 170 is 14 minutes of time before you recover.

We generally need more transparency:
- If we have pain, show the user what hurts if they want to see it.
