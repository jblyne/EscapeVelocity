# Tribute bounty hunters — 0.1.162

Each dominated, surviving world tracks hunters sent, hunters defeated, an active contract serial, and its next hiring day. First hiring is eligible one game day after domination; replacements wait two game days. Only one retaliation hunter is present at once. Pending contracts follow the pilot across travel and reload without increasing the sent count.

Player or allied-fleet destruction raises that employer’s daily tribute by 5,000 credits, with prior unpaid days settled at the old rate. Five credited defeats end hiring permanently and retain the 25,000 daily increase. Disabling, capturing, or another NPC destroying a hunter does not award the increase. Released or destroyed worlds do not pay tribute or dispatch hunters.

Employer appears in the contact name and a separate 16-second flight alert. The map footer aggregates daily income, contracts sent, credited defeats, and surrender for the selected system; its tooltip breaks these down by world. Older pilots normalize to empty hunter history.

Validation: tribute hunter test 37 checks; map domination 10; map screen 41; world activity 38; enemy kill reputation 13; planet debris 30; fleets 48; missions 285; campaign routes 457. All passed (959 checks total). Native visual checks and Mac export/startup also performed.
