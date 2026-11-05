# Writes the ORM materials in assets/materials/ from Poly Haven textures.
#   powershell -ExecutionPolicy Bypass -File tools\make_materials.ps1
param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$dir = Join-Path $Root "assets\materials"
New-Item -ItemType Directory -Force $dir | Out-Null
$utf8 = New-Object Text.UTF8Encoding $false

# uv scale = 1 / tile size in metres (Poly Haven lists real-world size per texture)
$defs = @(
  @{ n='wallpaper';     t='decrepit_wallpaper';         s='0.4';   tri='world'; tint='Color(0.86, 0.84, 0.8, 1)' },
  @{ n='floor_wood';    t='old_wooden_floor_03';        s='0.834'; tri='world'; tint='Color(0.9, 0.86, 0.82, 1)' },
  @{ n='ceiling';       t='white_plaster_02';           s='0.6';   tri='world'; tint='Color(0.8, 0.77, 0.72, 1)' },
  @{ n='rug';           t='quatrefoil_jacquard_fabric'; s='uv';    tri='none';  tint='Color(0.62, 0.52, 0.46, 1)' },
  @{ n='siding';        t='weathered_plank_siding';     s='0.637'; tri='world'; tint='Color(0.8, 0.8, 0.8, 1)' },
  @{ n='porch_deck';    t='wood_floor_deck';            s='0.556'; tri='world'; tint='Color(0.7, 0.68, 0.66, 1)' },
  @{ n='ground_leaves'; t='forest_leaves_04';           s='0.667'; tri='world'; tint='Color(0.8, 0.8, 0.8, 1)' },
  @{ n='door_wood';     t='old_wooden_floor_03';        s='0.834'; tri='local'; tint='Color(0.5, 0.4, 0.33, 1)' },
  @{ n='trim_wood';     t='old_wooden_floor_03';        s='1.5';   tri='world'; tint='Color(0.42, 0.33, 0.27, 1)' },
  @{ n='linoleum';      t='old_linoleum_flooring_01';   s='0.5';   tri='world'; tint='Color(0.85, 0.83, 0.8, 1)' },
  @{ n='concrete';      t='dirty_concrete';             s='0.333'; tri='world'; tint='Color(0.75, 0.74, 0.72, 1)' },
  @{ n='stone_wall';    t='plastered_stone_wall';       s='0.4';   tri='world'; tint='Color(0.72, 0.7, 0.66, 1)' },
  @{ n='plaster_wall';  t='painted_plaster_wall';       s='0.5';   tri='world'; tint='Color(0.82, 0.8, 0.72, 1)' },
  @{ n='june_wall';     t='painted_plaster_wall';       s='0.5';   tri='world'; tint='Color(0.86, 0.72, 0.72, 1)' },
  @{ n='roof';          t='weathered_plank_siding';     s='0.9';   tri='world'; tint='Color(0.32, 0.3, 0.3, 1)' },
  @{ n='beam_wood';     t='old_wooden_floor_03';        s='1.2';   tri='world'; tint='Color(0.35, 0.28, 0.23, 1)' },
  @{ n='counter_body';  t='old_wooden_floor_03';        s='1.0';   tri='world'; tint='Color(0.62, 0.6, 0.55, 1)' },
  @{ n='counter_top';   t='old_linoleum_flooring_01';   s='0.8';   tri='world'; tint='Color(0.7, 0.7, 0.68, 1)' }
)

foreach ($d in $defs) {
  $base = "res://assets/textures/$($d.t)/$($d.t)"
  $lines = @(
    '[gd_resource type="ORMMaterial3D" load_steps=4 format=3]', '',
    "[ext_resource type=`"Texture2D`" path=`"$($base)_diff_2k.jpg`" id=`"1_diff`"]",
    "[ext_resource type=`"Texture2D`" path=`"$($base)_arm_2k.jpg`" id=`"2_arm`"]",
    "[ext_resource type=`"Texture2D`" path=`"$($base)_nor_gl_2k.jpg`" id=`"3_nor`"]", '',
    '[resource]',
    "resource_name = `"$($d.n)`"",
    "albedo_color = $($d.tint)",
    'albedo_texture = ExtResource("1_diff")',
    'orm_texture = ExtResource("2_arm")',
    'normal_enabled = true',
    'normal_texture = ExtResource("3_nor")'
  )
  if ($d.s -ne 'uv') { $lines += "uv1_scale = Vector3($($d.s), $($d.s), $($d.s))" }
  if ($d.tri -ne 'none') { $lines += 'uv1_triplanar = true'; $lines += 'uv1_triplanar_sharpness = 4.0' }
  if ($d.tri -eq 'world') { $lines += 'uv1_world_triplanar = true' }
  $lines += 'texture_filter = 5'
  $path = Join-Path $dir "$($d.n).tres"
  [IO.File]::WriteAllText($path, (($lines -join "`n") + "`n"), $utf8)
}
Write-Output "wrote $($defs.Count) materials"
