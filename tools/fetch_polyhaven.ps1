# Downloads the Poly Haven (CC0) models and textures used by the game into assets/.
# Safe to re-run: files that already exist are skipped.
#   powershell -ExecutionPolicy Bypass -File tools\fetch_polyhaven.ps1
param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$h = @{ 'User-Agent' = 'pike-road-dev' }

# id = resolution
$models = [ordered]@{
  # milestone 1
  'Television_01'='2k'; 'sofa_03'='2k'; 'Rockingchair_01'='2k'; 'gothic_coffee_table'='2k'; 'side_table_tall_01'='2k'
  'vintage_wooden_drawer_01'='2k'; 'vintage_grandfather_clock_01'='2k'; 'vintage_oil_lamp'='2k'; 'Chandelier_01'='2k'
  'vintage_cabinet_01'='2k'; 'fancy_picture_frame_01'='2k'; 'ornate_mirror_01'='2k'
  # full house
  'electric_stove'='2k'; 'vintage_microwave'='2k'; 'GothicBed_01'='2k'; 'ClassicNightstand_01'='2k'; 'GothicCabinet_01'='2k'
  'vintage_day_bed'='2k'; 'painted_wooden_cabinet'='2k'; 'round_wooden_table_01'='2k'; 'WoodenChair_01'='2k'; 'dining_chair_02'='2k'
  'WoodenTable_03'='2k'; 'vintage_pocket_watch'='2k'; 'CheeseBox_01'='2k'; 'vintage_flashlight'='2k'; 'bolt_action_rifle_7_62'='2k'
  'power_box_01'='2k'; 'painted_wooden_chair_01'='2k'; 'hanging_picture_frame_02'='2k'; 'Shelf_01'='2k'; 'Ottoman_01'='2k'
  'vintage_electric_kettle'='1k'; 'tea_set_01'='1k'; 'wooden_cutting_board'='1k'; 'pot_enamel_01'='1k'; 'jug_01'='1k'
  'wine_bottles_01'='1k'; 'vintage_suitcase'='1k'; 'throw_pillows_01'='1k'; 'rubber_duck_toy'='1k'; 'worn_metal_rack'='1k'
  'steel_frame_shelves_01'='1k'; 'bench_vice_01'='1k'; 'cardboard_box_01'='1k'; 'old_military_crate'='1k'; 'wooden_crate_01'='1k'
  'Barrel_02'='1k'; 'metal_toolbox'='1k'; 'hatchet'='1k'; 'crowbar_01'='1k'; 'wooden_candlestick'='1k'
  'pull_chain_light_socket'='1k'; 'lightbulb_01'='1k'; 'wooden_bookshelf_worn'='1k'; 'book_encyclopedia_set_01'='1k'
  'wooden_bucket_01'='1k'; 'rusted_spade_01'='1k'; 'Lantern_01'='1k'; 'security_light'='1k'; 'painted_wooden_nightstand'='1k'; 'trashbag'='1k'
}
$textures = @('decrepit_wallpaper','old_wooden_floor_03','white_plaster_02','quatrefoil_jacquard_fabric','weathered_plank_siding',
  'wood_floor_deck','forest_leaves_04','old_linoleum_flooring_01','dirty_concrete','plastered_stone_wall','painted_plaster_wall')

function Get-File($url, $dest) {
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  if (Test-Path $dest) { return }
  Invoke-WebRequest -Uri $url -Headers $h -OutFile "$dest.part" -UseBasicParsing
  Move-Item "$dest.part" $dest -Force
}

foreach ($id in $models.Keys) {
  $res = $models[$id]
  $f = Invoke-RestMethod -Uri "https://api.polyhaven.com/files/$id" -Headers $h
  $g = $f.gltf.$res.gltf
  $dir = Join-Path $Root "assets\models\$id"
  Get-File $g.url (Join-Path $dir "$id.gltf")
  foreach ($p in $g.include.PSObject.Properties) { Get-File $p.Value.url (Join-Path $dir ($p.Name -replace '/', '\')) }
  Write-Output "model   $id ($res)"
}
foreach ($id in $textures) {
  $f = Invoke-RestMethod -Uri "https://api.polyhaven.com/files/$id" -Headers $h
  foreach ($map in 'Diffuse','nor_gl','arm') {
    $u = $f.$map.'2k'.jpg.url
    Get-File $u (Join-Path $Root "assets\textures\$id\$(Split-Path $u -Leaf)")
  }
  Write-Output "texture $id"
}
