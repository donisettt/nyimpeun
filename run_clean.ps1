# Run Flutter dengan output minimal - hanya tampilkan info penting
# Jalankan: .\run_clean.ps1

flutter run --suppress-analytics 2>&1 | Where-Object {
    $_ -match "flutter|error|Error|warning|Launching|Syncing|Hot|Quit|Reload|restart|Observatory|DevTools|Running|Built|Installing" -and
    $_ -notmatch "D/Flutter|D/Profile|W/HWUI|I/Choreographer|W/xample|I/xample|D/FlutterJNI|W/ApkAssets|I/WindowExt|I/Gralloc|I/flutter.*supabase|compiler allocated|Impeller"
}
