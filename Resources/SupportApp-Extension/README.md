# App Auto-Patch Extension for Root3 Support App

![alt](https://github.com/App-Auto-Patch/App-Auto-Patch/blob/9112d1cdab79e53c4e5d4276616e41dfa872f762/Images/AAP-Root3%20SupportApp%20Extension.png)

Adds an App Auto-Patch (AAP) tile to the [Root3 Support App](https://github.com/root3nl/SupportApp) showing the number of pending updates - clicking the tile triggers an immediate patch run. Requires AAP 3.6.0 or later (introduced the `xyz.techitout.appAutoPatchReport.plist` report file these scripts read from).

See the Support App wiki for background on how these pieces fit together: [Extensions](https://github.com/root3nl/SupportApp/wiki/Extensions), [Privileged Scripts](https://github.com/root3nl/SupportApp/wiki/Privileged-Scripts), [Configuration](https://github.com/root3nl/SupportApp/wiki/Configuration).

## Scripts

* **`aap_pending_updates.zsh`** - Populates the Extension with the count of apps currently queued for patching (read from AAP's report PLIST). Intended to run via `OnAppearAction`, so the count is refreshed every time the Support App popover appears.
* **`aap_install_now.zsh`** - Runs `appautopatch --workflow-install-now` to trigger an immediate patch run (bypassing any deferral), then re-runs `aap_pending_updates.zsh` to refresh the count once the run completes. Intended as the same Extension item's `PrivilegedScript` `Action` (triggered when the tile is clicked).

## Deployment

1. Deploy both scripts to the same folder on each Mac, owned by `root` with `755` permissions (a Support App Privileged Script requirement). The scripts default to `/Library/Management/AppAutoPatch/SupportApp/`, but you can deploy them anywhere as long as you update the `refresh_script_path` variable in `aap_install_now.zsh` to match.
2. Add a Support App Configuration Profile (preference domain `nl.root3.support`) containing a single `Extension` item that sets both `OnAppearAction` (refresh the count) and `Action`/`ActionType` (trigger a patch run when clicked) to the paths above. See the example snippet below.
3. **Important:** per Support App's requirements, the `Action` and `OnAppearAction` paths **must** be set via a Configuration Profile - values set locally via `defaults write` (e.g. while testing in Configurator Mode) are not honored for Privileged Scripts.

## Example Configuration Profile snippet

This example assumes the scripts are deployed to their default path. Combine with the rest of your Support App configuration profile's `Rows` array - see [Configuration](https://github.com/root3nl/SupportApp/wiki/Configuration#rows) for the full `Rows`/`Row`/`Items` structure.

```xml
<dict>
    <key>Items</key>
    <array>
        <dict>
            <key>Type</key>
            <string>Extension</string>
            <key>ExtensionID</key>
            <string>aap_pending_updates</string>
            <key>Title</key>
            <string>App Updates</string>
            <key>Subtitle</key>
            <string>Update Now</string>
            <key>Symbol</key>
            <string>waveform.path.ecg</string>
            <key>ActionType</key>
            <string>PrivilegedScript</string>
            <key>Action</key>
            <string>/Library/Management/AppAutoPatch/SupportApp/aap_install_now.zsh</string>
            <key>OnAppearAction</key>
            <string>/Library/Management/AppAutoPatch/SupportApp/aap_pending_updates.zsh</string>
        </dict>
    </array>
</dict>
```

## Notes

* `--workflow-install-now` displays all of AAP's normal dialogs to the end user (deferral/hard-deadline, patching progress, etc.), regardless of `InteractiveMode` - it does not patch silently in the background. See [Workflows](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Workflows#workflow-install-now-self-service) for details.
* If AAP hasn't completed its first discovery run yet, the report PLIST won't exist - `aap_pending_updates.zsh` treats this as zero pending updates rather than an error.
* Both scripts are self-contained and only need the variables at the top edited if you've customized AAP's install folder (`appAutoPatchFolder`) or deployed these scripts somewhere other than the suggested default path.
