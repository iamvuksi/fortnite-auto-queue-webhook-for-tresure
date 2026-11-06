# Fortnite Queue Loop by Krstic

This is a separate AutoHotkey v2 macro limited to 1920×1080. It searches the screenshots for lobby **PLAY** and results **PLAY AGAIN**, including the shifted position with **STAY WITH TEAM**. It ignores that team button.

## Run it

Right-click the ZIP and choose **Extract All**; do not run the script from inside the ZIP. Keep the extracted `images` folder beside the `.ahk` file. Install AutoHotkey v2, open `Fortnite Queue Loop.ahk`, focus Fortnite, then press **F9** to start. Press **F10** to stop.

A click-through panel shows games completed and session runtime while running. The count increases when the macro finds a new results **PLAY AGAIN** screen.

## Optional Discord webhook

Create a webhook in your Discord server’s **Server Settings → Integrations → Webhooks**, copy its URL, paste it into the macro’s optional field, then click **Test**. The macro does not save the URL in a file. By default it sends one session summary when you stop. You can also enable messages after each finished game and when the on-screen Pirate Shop Access reward banner appears. The banner check uses an image reference and may miss if Fortnite changes the graphic or its display scaling.

The Pirate Shop Access alert checks for the centered “YOU FOUND PIRATE SHOP ACCESS” reward banner using a supplied image reference. Reference image source: Pro-Gamer.gg Fortnite Pirate Shop guide (https://pro-gamer.gg/fortnite-pirate-shop-guide-best-chest-spots-access-token-free-item-shop-14-days/). Discord webhooks accept HTTP POST messages to a generated URL. See [Discord’s webhook documentation](https://discord.com/developers/docs/resources/webhook#execute-webhook).
