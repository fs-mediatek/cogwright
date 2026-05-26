extends Node

# Zentrale Versions-Konstante â€” wird bei jedem Release manuell bumpd
# oder via build_release.ps1 -BumpPatch.
# Format: MAJOR.MINOR.PATCH (SemVer-light).
const VERSION: String = "0.2.1"

# URL fuer die Version-Check-Datei (manifest.json).
# Format: {"version": "0.2.1", "download_url": "https://...", "notes": "..."}
# Leer lassen oder URL setzen wenn Selfhosted-Update-Check aktiv sein soll.
const UPDATE_MANIFEST_URL: String = ""

func is_newer(remote: String) -> bool:
	# Returns true wenn remote > VERSION.
	var a: PackedStringArray = VERSION.split(".")
	var b: PackedStringArray = remote.split(".")
	for i in range(max(a.size(), b.size())):
		var av: int = int(a[i]) if i < a.size() else 0
		var bv: int = int(b[i]) if i < b.size() else 0
		if bv > av: return true
		if bv < av: return false
	return false
