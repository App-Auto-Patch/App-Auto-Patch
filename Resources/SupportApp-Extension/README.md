# App Auto-Patch Extension for Root3 Support App

![alt](https://github.com/App-Auto-Patch/App-Auto-Patch/blob/9112d1cdab79e53c4e5d4276616e41dfa872f762/Images/AAP-Root3%20SupportApp%20Extension.png)

Adds an App Auto-Patch (AAP) tile to the [Root3 Support App](https://github.com/root3nl/SupportApp) showing the number of pending updates, with a choice of two `Action` scripts for what happens when the tile is clicked (see below). Requires AAP 3.6.0 or later (introduced the `xyz.techitout.appAutoPatchReport.plist` report file these scripts read from).

See the Support App wiki for background on how these pieces fit together: [Extensions](https://github.com/root3nl/SupportApp/wiki/Extensions), [Privileged Scripts](https://github.com/root3nl/SupportApp/wiki/Privileged-Scripts), [Configuration](https://github.com/root3nl/SupportApp/wiki/Configuration).

## Scripts

* **`aap_pending_updates.zsh`** - Populates the Extension with the count of apps currently queued for patching (read from AAP's report PLIST). Intended to run via `OnAppearAction`, so the count is refreshed every time the Support App popover appears. Used alongside either `Action` script below.

Two options for the tile's `Action` (what happens when it's clicked) - pick whichever fits your environment, only one is needed:

* **`aap_pending_apps_dialog.zsh`** - Shows a swiftDialog list of pending apps first (icon, name, "Current Version → New Version" subtitle) with "Install Now"/"Later" buttons - no deferral timer or menu. "Install Now" kicks off `appautopatch --workflow-install-now` in the background; either button then re-runs `aap_pending_updates.zsh` to refresh the count. If there are zero pending apps when clicked, shows a brief "You're all up to date!" message instead. Reads the same managed/local preferences AAP itself uses (`DialogIcon`, `UseOverlayIcon`, `BannerImage`/`BannerTitle`/`BannerHeight`, `AppTitle`, `DialogOnTop`, and the `display_string_version_current`/`display_string_version_new`/`display_string_there_are`/`display_string_deferral_button2` language overrides) so its look and wording stay consistent with AAP's own dialogs. The "Later" button's text can optionally be customized via a new (not part of AAP's own manifests) managed preference key, `display_string_pendingapps_button_later`, alongside the other `dialogElements` entries - defaults to "Later" if not set. Best if you want end users to see what's pending and have a chance to defer before anything happens.
* **`aap_install_now.zsh`** - Skips straight to running `appautopatch --workflow-install-now`, with no pending-apps list or confirmation dialog first, then re-runs `aap_pending_updates.zsh` to refresh the count once the run completes. Best if you'd rather have the tile act as a single-click "patch now" button, since AAP's own patching dialogs still appear as normal (deferral, hard-deadline, progress, etc. - see Notes below) once the workflow starts.

## Deployment

1. Deploy `aap_pending_updates.zsh` and whichever `Action` script you chose to the same folder on each Mac, owned by `root` with `755` permissions (a Support App Privileged Script requirement). The scripts default to `/Library/Management/AppAutoPatch/SupportApp/`, but you can deploy them anywhere as long as you update the `refresh_script_path` variable in `aap_pending_apps_dialog.zsh` / `aap_install_now.zsh` to match.
2. Add a Support App Configuration Profile (preference domain `nl.root3.support`) containing a single `Extension` item that sets `OnAppearAction` (refresh the count) to `aap_pending_updates.zsh`, and `Action`/`ActionType` to whichever script you chose above. See the example snippet below (uses `aap_pending_apps_dialog.zsh` as the `Action` - swap in `aap_install_now.zsh` if you prefer that option).
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
            <string>/Library/Management/AppAutoPatch/SupportApp/aap_pending_apps_dialog.zsh</string>
            <key>OnAppearAction</key>
            <string>/Library/Management/AppAutoPatch/SupportApp/aap_pending_updates.zsh</string>
        </dict>
    </array>
</dict>
```

## Notes

* `--workflow-install-now` displays all of AAP's normal dialogs to the end user (deferral/hard-deadline, patching progress, etc.), regardless of `InteractiveMode` - it does not patch silently in the background. See [Workflows](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Workflows#workflow-install-now-self-service) for details. This also means an app already open when "Install Now" is clicked from `aap_pending_apps_dialog.zsh` will still prompt the user to close it, the same as any other AAP-driven patch run.
* If AAP hasn't completed its first discovery run yet, the report PLIST won't exist - `aap_pending_updates.zsh` and `aap_pending_apps_dialog.zsh` both treat this as zero pending updates rather than an error.
* All scripts are self-contained and only need the variables at the top edited if you've customized AAP's install folder (`appAutoPatchFolder`) or deployed these scripts somewhere other than the suggested default path.
