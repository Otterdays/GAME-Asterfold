param()

# Generates the layered adventurer kit:
#   mara_layers_field.png      packed field body layers, one 576x320 sheet per layer
#   mara_layers_doll.png       packed paper-doll body layers, one 96x128 frame per layer
#   mara_hair_field.png        three hair styles stacked, each a full field sheet
#   mara_hair_doll.png         three south-idle hair styles packed horizontally
#   mara_prototype.png         flattened field sheet (crop hair, starter colours)
#
# Layer orders must match ActorLayerIds. Hair style order must match AppearanceCatalog.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$gameRoot = Split-Path -Parent $PSScriptRoot
$sourceDirectory = Join-Path $gameRoot 'art_source\characters\mara'
$runtimeDirectory = Join-Path $gameRoot 'assets\generated\characters\mara'

New-Item -ItemType Directory -Force -Path $sourceDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $runtimeDirectory | Out-Null

$frameWidth = 48
$frameHeight = 64
$columns = 12
$rows = 5
$dollScale = 2
$dollWidth = $frameWidth * $dollScale
$dollHeight = $frameHeight * $dollScale
$idleFrames = 4
$walkFrames = 8

$palette = @{
	Outline = [System.Drawing.ColorTranslator]::FromHtml('#2A241C')
	HairDark = [System.Drawing.ColorTranslator]::FromHtml('#3D2814')
	Hair = [System.Drawing.ColorTranslator]::FromHtml('#6B4423')
	HairLight = [System.Drawing.ColorTranslator]::FromHtml('#8B5E3C')
	SkinShadow = [System.Drawing.ColorTranslator]::FromHtml('#C48662')
	Skin = [System.Drawing.ColorTranslator]::FromHtml('#D7A07B')
	SkinLight = [System.Drawing.ColorTranslator]::FromHtml('#EDBE91')
	ShirtDark = [System.Drawing.ColorTranslator]::FromHtml('#5C3A1A')
	Shirt = [System.Drawing.ColorTranslator]::FromHtml('#8B5A2B')
	ShirtLight = [System.Drawing.ColorTranslator]::FromHtml('#A6723E')
	JeansDark = [System.Drawing.ColorTranslator]::FromHtml('#243A5C')
	Jeans = [System.Drawing.ColorTranslator]::FromHtml('#3B5A8A')
	JeansLight = [System.Drawing.ColorTranslator]::FromHtml('#5A7AAB')
	BootDark = [System.Drawing.ColorTranslator]::FromHtml('#8B7355')
	Boot = [System.Drawing.ColorTranslator]::FromHtml('#C4A574')
	BootLight = [System.Drawing.ColorTranslator]::FromHtml('#D4BC94')
	Belt = [System.Drawing.ColorTranslator]::FromHtml('#4A3728')
	Eye = [System.Drawing.ColorTranslator]::FromHtml('#F2E6D8')
	Iris = [System.Drawing.ColorTranslator]::FromHtml('#3A2A22')
}

$hairStyleIds = @('hair.crop', 'hair.fringe', 'hair.tousle')

$fieldLayerOrder = @(
	'layer.l_thigh', 'layer.r_thigh',
	'layer.l_knee', 'layer.r_knee',
	'layer.l_calf', 'layer.r_calf',
	'layer.l_foot', 'layer.r_foot',
	'layer.pelvis', 'layer.waist', 'layer.abdomen', 'layer.torso',
	'layer.l_upper_arm', 'layer.r_upper_arm',
	'layer.l_forearm', 'layer.r_forearm',
	'layer.l_hand', 'layer.r_hand',
	'layer.l_shoulder', 'layer.r_shoulder',
	'layer.head'
)

$fingerLayerOrder = @(
	'layer.l_thumb', 'layer.l_index', 'layer.l_middle', 'layer.l_ring', 'layer.l_little',
	'layer.r_thumb', 'layer.r_index', 'layer.r_middle', 'layer.r_ring', 'layer.r_little'
)

$dollLayerOrder = @()
foreach ($layer in $fieldLayerOrder) {
	$dollLayerOrder += $layer
	if ($layer -eq 'layer.r_hand') {
		$dollLayerOrder += $fingerLayerOrder
	}
}

function New-Rect {
	param(
		[int]$X,
		[int]$Y,
		[int]$Width,
		[int]$Height,
		[System.Drawing.Color]$Color,
		[bool]$Absolute = $false
	)
	return @{ X = $X; Y = $Y; Width = $Width; Height = $Height; Color = $Color; Absolute = $Absolute }
}

function Add-Rect {
	param(
		[System.Collections.Generic.List[object]]$Target,
		[int]$X,
		[int]$Y,
		[int]$Width,
		[int]$Height,
		[System.Drawing.Color]$Color,
		[bool]$Absolute = $false
	)
	if ($Width -le 0 -or $Height -le 0) {
		return
	}
	$Target.Add((New-Rect $X $Y $Width $Height $Color $Absolute)) | Out-Null
}

function Get-Pose {
	param([int]$Frame)

	if ($Frame -lt $idleFrames) {
		$idleBob = @(0, 0, 1, 0)
		return @{
			Bob = $idleBob[$Frame]
			HairBob = $idleBob[$Frame]
			LeftX = $(if ($Frame -eq 3) { 1 } else { 0 })
			RightX = $(if ($Frame -eq 3) { -1 } else { 0 })
			LeftY = 0
			RightY = 0
			LeftArmX = $(if ($Frame -eq 3) { -1 } else { 0 })
			RightArmX = $(if ($Frame -eq 3) { 1 } else { 0 })
			LeftArmY = 0
			RightArmY = 0
			Blink = ($Frame -eq 2)
		}
	}

	$phase = $Frame - $idleFrames
	$leftX = @(2, 1, 0, -1, -2, -1, 0, 1)[$phase]
	$rightX = -$leftX
	$bob = @(0, 1, 0, 1, 0, 1, 0, 1)[$phase]
	$hairBob = @(1, 0, 1, 0, 1, 0, 1, 0)[$phase]
	$leftY = $(if ($leftX -ge 2) { 1 } elseif ($leftX -le -2) { -1 } else { 0 })
	$rightY = $(if ($rightX -ge 2) { 1 } elseif ($rightX -le -2) { -1 } else { 0 })
	return @{
		Bob = $bob
		HairBob = $hairBob
		LeftX = $leftX
		RightX = $rightX
		LeftY = $leftY
		RightY = $rightY
		LeftArmX = -$leftX
		RightArmX = -$rightX
		LeftArmY = $(if ($leftX -ge 1) { 1 } elseif ($leftX -le -1) { -1 } else { 0 })
		RightArmY = $(if ($rightX -ge 1) { 1 } elseif ($rightX -le -1) { -1 } else { 0 })
		Blink = $false
	}
}

function Get-BodyLayers {
	param(
		[int]$Row,
		[hashtable]$Pose,
		[bool]$IncludeFingers
	)

	$bob = $Pose.Bob
	$lx = $Pose.LeftX
	$rx = $Pose.RightX
	$ly = $Pose.LeftY
	$ry = $Pose.RightY
	$lax = $Pose.LeftArmX
	$rax = $Pose.RightArmX
	$lay = $Pose.LeftArmY
	$ray = $Pose.RightArmY
	$blink = $Pose.Blink
	$east = ($Row -eq 2)
	$north = ($Row -eq 0)
	$south = ($Row -eq 4)
	$southish = ($Row -ge 3)
	$northish = ($Row -le 1)

	$layers = [ordered]@{}
	foreach ($layerId in ($fieldLayerOrder + $fingerLayerOrder)) {
		$layers[$layerId] = [System.Collections.Generic.List[object]]::new()
	}

	# Jeans and boots: stride lives in the legs. Pocket only on south-facing pelvis.
	Add-Rect $layers['layer.l_thigh'] (16 + $lx) (46 + $ly) 7 6 $palette.Outline
	Add-Rect $layers['layer.l_thigh'] (17 + $lx) (46 + $ly) 5 6 $palette.Jeans
	Add-Rect $layers['layer.l_thigh'] (18 + $lx) (47 + $ly) 2 3 $palette.JeansLight
	Add-Rect $layers['layer.r_thigh'] (25 + $rx) (46 + $ry) 7 6 $palette.Outline
	Add-Rect $layers['layer.r_thigh'] (26 + $rx) (46 + $ry) 5 6 $palette.Jeans
	Add-Rect $layers['layer.r_thigh'] (28 + $rx) (47 + $ry) 2 3 $palette.JeansDark
	Add-Rect $layers['layer.l_knee'] (16 + $lx) (52 + $ly) 7 2 $palette.Outline
	Add-Rect $layers['layer.l_knee'] (17 + $lx) (52 + $ly) 5 2 $palette.JeansLight
	Add-Rect $layers['layer.r_knee'] (25 + $rx) (52 + $ry) 7 2 $palette.Outline
	Add-Rect $layers['layer.r_knee'] (26 + $rx) (52 + $ry) 5 2 $palette.JeansLight
	Add-Rect $layers['layer.l_calf'] (16 + $lx) (54 + $ly) 7 4 $palette.Outline
	Add-Rect $layers['layer.l_calf'] (17 + $lx) (54 + $ly) 5 3 $palette.Jeans
	Add-Rect $layers['layer.l_calf'] (17 + $lx) (57 + $ly) 5 1 $palette.JeansDark
	Add-Rect $layers['layer.r_calf'] (25 + $rx) (54 + $ry) 7 4 $palette.Outline
	Add-Rect $layers['layer.r_calf'] (26 + $rx) (54 + $ry) 5 3 $palette.Jeans
	Add-Rect $layers['layer.r_calf'] (26 + $rx) (57 + $ry) 5 1 $palette.JeansDark
	Add-Rect $layers['layer.l_foot'] (15 + $lx) (57 + $ly) 9 4 $palette.Outline
	Add-Rect $layers['layer.l_foot'] (16 + $lx) (57 + $ly) 7 3 $palette.Boot
	Add-Rect $layers['layer.l_foot'] (16 + $lx) (60 + $ly) 7 1 $palette.BootDark
	Add-Rect $layers['layer.l_foot'] (17 + $lx) (58 + $ly) 3 1 $palette.BootLight
	Add-Rect $layers['layer.l_foot'] (19 + $lx) (57 + $ly) 1 1 $palette.Belt
	Add-Rect $layers['layer.r_foot'] (24 + $rx) (57 + $ry) 9 4 $palette.Outline
	Add-Rect $layers['layer.r_foot'] (25 + $rx) (57 + $ry) 7 3 $palette.Boot
	Add-Rect $layers['layer.r_foot'] (25 + $rx) (60 + $ry) 7 1 $palette.BootDark
	Add-Rect $layers['layer.r_foot'] (26 + $rx) (58 + $ry) 3 1 $palette.BootLight
	Add-Rect $layers['layer.r_foot'] (28 + $rx) (57 + $ry) 1 1 $palette.Belt

	Add-Rect $layers['layer.pelvis'] 17 (40 + $bob) 14 6 $palette.Outline
	Add-Rect $layers['layer.pelvis'] 18 (40 + $bob) 12 6 $palette.Jeans
	Add-Rect $layers['layer.pelvis'] 23 (41 + $bob) 1 5 $palette.JeansDark
	if ($southish) {
		Add-Rect $layers['layer.pelvis'] 25 (42 + $bob) 4 3 $palette.JeansDark
		Add-Rect $layers['layer.pelvis'] 26 (43 + $bob) 2 1 $palette.JeansLight
		Add-Rect $layers['layer.pelvis'] 25 (42 + $bob) 1 3 $palette.Belt
	}
	elseif ($north) {
		Add-Rect $layers['layer.pelvis'] 20 (43 + $bob) 8 2 $palette.JeansDark
	}
	Add-Rect $layers['layer.waist'] 17 (37 + $bob) 14 4 $palette.Outline
	Add-Rect $layers['layer.waist'] 18 (37 + $bob) 12 3 $palette.Belt
	Add-Rect $layers['layer.waist'] 22 (38 + $bob) 4 1 $palette.BootLight
	Add-Rect $layers['layer.waist'] 19 (37 + $bob) 1 3 $palette.JeansDark
	Add-Rect $layers['layer.waist'] 28 (37 + $bob) 1 3 $palette.JeansDark

	# Brown t-shirt: crew neck, short sleeves, hem over the belt.
	Add-Rect $layers['layer.abdomen'] 17 (33 + $bob) 14 5 $palette.Outline
	Add-Rect $layers['layer.abdomen'] 18 (33 + $bob) 12 5 $palette.Shirt
	Add-Rect $layers['layer.abdomen'] 19 (34 + $bob) 3 2 $palette.ShirtLight
	Add-Rect $layers['layer.abdomen'] 18 (36 + $bob) 12 1 $palette.ShirtDark
	Add-Rect $layers['layer.torso'] 16 (22 + $bob) 16 12 $palette.Outline
	Add-Rect $layers['layer.torso'] 17 (23 + $bob) 14 11 $palette.Shirt
	Add-Rect $layers['layer.torso'] 18 (25 + $bob) 4 6 $palette.ShirtLight
	Add-Rect $layers['layer.torso'] 27 (26 + $bob) 2 5 $palette.ShirtDark
	Add-Rect $layers['layer.torso'] 20 (32 + $bob) 8 1 $palette.ShirtDark
	if ($southish -or $east) {
		Add-Rect $layers['layer.torso'] 21 (23 + $bob) 6 3 $palette.Skin
		Add-Rect $layers['layer.torso'] 22 (23 + $bob) 4 1 $palette.ShirtDark
		Add-Rect $layers['layer.torso'] 22 (24 + $bob) 4 2 $palette.SkinLight
	}
	if ($northish) {
		Add-Rect $layers['layer.torso'] 18 (24 + $bob) 12 2 $palette.ShirtDark
	}

	Add-Rect $layers['layer.l_upper_arm'] (12 + $lax) (24 + $bob + $lay) 5 8 $palette.Outline
	Add-Rect $layers['layer.l_upper_arm'] (13 + $lax) (24 + $bob + $lay) 3 8 $palette.Shirt
	Add-Rect $layers['layer.l_upper_arm'] (13 + $lax) (30 + $bob + $lay) 3 2 $palette.ShirtDark
	Add-Rect $layers['layer.r_upper_arm'] (31 + $rax) (24 + $bob + $ray) 5 8 $palette.Outline
	Add-Rect $layers['layer.r_upper_arm'] (32 + $rax) (24 + $bob + $ray) 3 8 $palette.Shirt
	Add-Rect $layers['layer.r_upper_arm'] (32 + $rax) (30 + $bob + $ray) 3 2 $palette.ShirtDark
	Add-Rect $layers['layer.l_forearm'] (12 + $lax) (32 + $bob + $lay) 5 8 $palette.Outline
	Add-Rect $layers['layer.l_forearm'] (13 + $lax) (32 + $bob + $lay) 3 8 $palette.Skin
	Add-Rect $layers['layer.l_forearm'] (13 + $lax) (33 + $bob + $lay) 1 4 $palette.SkinLight
	Add-Rect $layers['layer.r_forearm'] (31 + $rax) (32 + $bob + $ray) 5 8 $palette.Outline
	Add-Rect $layers['layer.r_forearm'] (32 + $rax) (32 + $bob + $ray) 3 8 $palette.Skin
	Add-Rect $layers['layer.r_forearm'] (34 + $rax) (33 + $bob + $ray) 1 4 $palette.SkinShadow
	Add-Rect $layers['layer.l_hand'] (12 + $lax) (40 + $bob + $lay) 5 5 $palette.Outline
	Add-Rect $layers['layer.l_hand'] (13 + $lax) (40 + $bob + $lay) 3 4 $palette.Skin
	Add-Rect $layers['layer.l_hand'] (12 + $lax) (41 + $bob + $lay) 2 2 $palette.SkinLight
	Add-Rect $layers['layer.r_hand'] (31 + $rax) (40 + $bob + $ray) 5 5 $palette.Outline
	Add-Rect $layers['layer.r_hand'] (32 + $rax) (40 + $bob + $ray) 3 4 $palette.Skin
	Add-Rect $layers['layer.r_hand'] (34 + $rax) (41 + $bob + $ray) 2 2 $palette.SkinShadow
	Add-Rect $layers['layer.l_shoulder'] (12 + $lax) (22 + $bob) 6 5 $palette.Outline
	Add-Rect $layers['layer.l_shoulder'] (13 + $lax) (22 + $bob) 4 4 $palette.Shirt
	Add-Rect $layers['layer.l_shoulder'] (13 + $lax) (23 + $bob) 2 2 $palette.ShirtLight
	Add-Rect $layers['layer.r_shoulder'] (30 + $rax) (22 + $bob) 6 5 $palette.Outline
	Add-Rect $layers['layer.r_shoulder'] (31 + $rax) (22 + $bob) 4 4 $palette.Shirt
	Add-Rect $layers['layer.r_shoulder'] (33 + $rax) (23 + $bob) 2 2 $palette.ShirtDark

	if ($east) {
		# Profile: tuck the far arm so the silhouette reads as a side view.
		$layers['layer.l_upper_arm'].Clear()
		$layers['layer.l_forearm'].Clear()
		$layers['layer.l_hand'].Clear()
		$layers['layer.l_shoulder'].Clear()
		Add-Rect $layers['layer.l_shoulder'] 17 (23 + $bob) 4 4 $palette.Outline
		Add-Rect $layers['layer.l_shoulder'] 18 (23 + $bob) 2 3 $palette.ShirtDark
	}

	$headY = 4 + $bob
	Add-Rect $layers['layer.head'] 16 $headY 16 18 $palette.Outline
	Add-Rect $layers['layer.head'] 17 ($headY + 2) 14 15 $palette.Skin
	Add-Rect $layers['layer.head'] 18 ($headY + 3) 4 5 $palette.SkinLight
	Add-Rect $layers['layer.head'] 21 ($headY + 15) 6 4 $palette.Skin
	Add-Rect $layers['layer.head'] 16 ($headY + 7) 2 4 $palette.SkinShadow
	Add-Rect $layers['layer.head'] 30 ($headY + 7) 2 4 $palette.SkinShadow

	if ($north) {
		Add-Rect $layers['layer.head'] 17 ($headY + 3) 14 14 $palette.SkinShadow
	}
	elseif ($Row -eq 1) {
		Add-Rect $layers['layer.head'] 16 ($headY + 4) 7 12 $palette.SkinShadow
		Add-Rect $layers['layer.head'] 28 ($headY + 8) 2 2 $palette.Outline
		Add-Rect $layers['layer.head'] 30 ($headY + 10) 2 3 $palette.SkinLight
	}
	elseif ($east) {
		Add-Rect $layers['layer.head'] 16 ($headY + 3) 8 14 $palette.SkinShadow
		Add-Rect $layers['layer.head'] 28 ($headY + 7) 3 3 $palette.SkinShadow
		Add-Rect $layers['layer.head'] 29 ($headY + 8) 2 2 $palette.Outline
		if ($blink) {
			Add-Rect $layers['layer.head'] 29 ($headY + 9) 2 1 $palette.Outline
		}
		else {
			Add-Rect $layers['layer.head'] 29 ($headY + 8) 2 2 $palette.Iris
			Add-Rect $layers['layer.head'] 29 ($headY + 8) 1 1 $palette.Eye
		}
		Add-Rect $layers['layer.head'] 31 ($headY + 11) 2 3 $palette.SkinLight
		Add-Rect $layers['layer.head'] 24 ($headY + 13) 4 1 $palette.SkinShadow
	}
	elseif ($Row -eq 3) {
		Add-Rect $layers['layer.head'] 17 ($headY + 4) 6 8 $palette.SkinShadow
		if ($blink) {
			Add-Rect $layers['layer.head'] 27 ($headY + 8) 2 1 $palette.Outline
		}
		else {
			Add-Rect $layers['layer.head'] 27 ($headY + 8) 2 2 $palette.Iris
			Add-Rect $layers['layer.head'] 27 ($headY + 8) 1 1 $palette.Eye
		}
		Add-Rect $layers['layer.head'] 29 ($headY + 11) 2 3 $palette.SkinLight
		Add-Rect $layers['layer.head'] 23 ($headY + 13) 4 1 $palette.SkinShadow
	}
	else {
		if ($blink) {
			Add-Rect $layers['layer.head'] 19 ($headY + 8) 2 1 $palette.Outline
			Add-Rect $layers['layer.head'] 27 ($headY + 8) 2 1 $palette.Outline
		}
		else {
			Add-Rect $layers['layer.head'] 19 ($headY + 8) 2 2 $palette.Iris
			Add-Rect $layers['layer.head'] 27 ($headY + 8) 2 2 $palette.Iris
			Add-Rect $layers['layer.head'] 19 ($headY + 8) 1 1 $palette.Eye
			Add-Rect $layers['layer.head'] 27 ($headY + 8) 1 1 $palette.Eye
		}
		Add-Rect $layers['layer.head'] 19 ($headY + 7) 2 1 $palette.HairDark
		Add-Rect $layers['layer.head'] 27 ($headY + 7) 2 1 $palette.HairDark
		Add-Rect $layers['layer.head'] 23 ($headY + 10) 2 2 $palette.SkinShadow
		Add-Rect $layers['layer.head'] 24 ($headY + 11) 1 1 $palette.SkinLight
		Add-Rect $layers['layer.head'] 22 ($headY + 13) 4 1 $palette.SkinShadow
		Add-Rect $layers['layer.head'] 23 ($headY + 14) 2 1 $palette.Outline
	}

	if (-not $IncludeFingers) {
		return $layers
	}

	Add-Rect $layers['layer.l_thumb'] 18 84 5 7 $palette.Skin $true
	Add-Rect $layers['layer.l_thumb'] 18 84 2 3 $palette.SkinLight $true
	Add-Rect $layers['layer.l_index'] 22 90 3 9 $palette.Skin $true
	Add-Rect $layers['layer.l_middle'] 26 90 3 10 $palette.Skin $true
	Add-Rect $layers['layer.l_ring'] 30 90 3 9 $palette.Skin $true
	Add-Rect $layers['layer.l_little'] 34 92 3 7 $palette.Skin $true
	Add-Rect $layers['layer.r_thumb'] 73 84 5 7 $palette.Skin $true
	Add-Rect $layers['layer.r_thumb'] 76 84 2 3 $palette.SkinShadow $true
	Add-Rect $layers['layer.r_index'] 71 90 3 9 $palette.Skin $true
	Add-Rect $layers['layer.r_middle'] 67 90 3 10 $palette.Skin $true
	Add-Rect $layers['layer.r_ring'] 63 90 3 9 $palette.Skin $true
	Add-Rect $layers['layer.r_little'] 59 92 3 7 $palette.Skin $true
	return $layers
}

function Get-HairLayers {
	param(
		[int]$Style,
		[int]$Row,
		[hashtable]$Pose
	)

	$rects = [System.Collections.Generic.List[object]]::new()
	$y = 2 + $Pose.HairBob
	$southish = ($Row -ge 3)
	$east = ($Row -eq 2)
	$north = ($Row -eq 0)

	Add-Rect $rects 16 $y 16 7 $palette.Outline
	Add-Rect $rects 17 ($y + 1) 14 6 $palette.Hair
	Add-Rect $rects 19 $y 6 2 $palette.HairLight
	Add-Rect $rects 17 ($y + 2) 2 6 $palette.HairDark
	Add-Rect $rects 29 ($y + 2) 2 6 $palette.HairDark
	Add-Rect $rects 21 ($y + 1) 2 1 $palette.HairLight
	Add-Rect $rects 25 ($y + 1) 2 1 $palette.HairDark

	if ($north -or $Row -eq 1) {
		Add-Rect $rects 17 ($y + 5) 14 11 $palette.Hair
		Add-Rect $rects 19 ($y + 6) 10 3 $palette.HairDark
		Add-Rect $rects 22 ($y + 8) 4 2 $palette.HairLight
	}
	if ($east) {
		Add-Rect $rects 16 ($y + 2) 9 11 $palette.Hair
		Add-Rect $rects 17 ($y + 3) 5 5 $palette.HairDark
		Add-Rect $rects 15 $y 4 3 $palette.HairLight
	}
	if ($southish) {
		Add-Rect $rects 16 ($y + 5) 2 5 $palette.Hair
		Add-Rect $rects 30 ($y + 5) 2 5 $palette.Hair
	}

	if ($Style -eq 1) {
		# Short fringe: bangs over the forehead on forward facings.
		if ($southish) {
			Add-Rect $rects 17 ($y + 5) 14 4 $palette.Hair
			Add-Rect $rects 19 ($y + 6) 4 2 $palette.HairLight
			Add-Rect $rects 24 ($y + 6) 3 3 $palette.HairDark
		}
		elseif ($east) {
			Add-Rect $rects 24 ($y + 4) 8 5 $palette.Hair
			Add-Rect $rects 26 ($y + 5) 4 2 $palette.HairLight
		}
	}
	elseif ($Style -eq 2) {
		# Short tousle: extra tufts that bounce with HairBob.
		Add-Rect $rects 18 ($y - 1) 4 3 $palette.Hair
		Add-Rect $rects 26 ($y - 1) 5 3 $palette.Hair
		Add-Rect $rects 22 ($y - 2) 3 3 $palette.HairLight
		Add-Rect $rects 27 $y 3 2 $palette.HairDark
		if ($southish) {
			Add-Rect $rects 20 ($y + 5) 3 3 $palette.HairLight
		}
	}
	else {
		# Crop: ears peek on south and east.
		if ($southish -or $east) {
			Add-Rect $rects 15 ($y + 8) 2 4 $palette.Skin
			Add-Rect $rects 31 ($y + 8) 2 4 $palette.Skin
		}
	}

	return $rects
}

function Draw-Rects {
	param(
		[System.Drawing.Graphics]$Canvas,
		$Rects,
		[int]$OriginX,
		[int]$OriginY,
		[int]$Scale
	)
	if ($null -eq $Rects) {
		return
	}
	foreach ($rect in $Rects) {
		$brush = [System.Drawing.SolidBrush]::new($rect.Color)
		try {
			if ($rect.Absolute) {
				$Canvas.FillRectangle($brush, ($OriginX + $rect.X), ($OriginY + $rect.Y), $rect.Width, $rect.Height)
			}
			else {
				$Canvas.FillRectangle(
					$brush,
					($OriginX + $rect.X * $Scale),
					($OriginY + $rect.Y * $Scale),
					($rect.Width * $Scale),
					($rect.Height * $Scale)
				)
			}
		}
		finally {
			$brush.Dispose()
		}
	}
}

function New-Canvas {
	param([int]$Width, [int]$Height)
	$bitmap = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
	$graphics.Clear([System.Drawing.Color]::Transparent)
	$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
	$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
	$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
	return @{ Bitmap = $bitmap; Graphics = $graphics }
}

$sheetWidth = $frameWidth * $columns
$sheetHeight = $frameHeight * $rows

$fieldCanvas = New-Canvas -Width $sheetWidth -Height ($sheetHeight * $fieldLayerOrder.Count)
$dollCanvas = New-Canvas -Width ($dollWidth * $dollLayerOrder.Count) -Height $dollHeight
$flatCanvas = New-Canvas -Width $sheetWidth -Height $sheetHeight
$hairFieldCanvas = New-Canvas -Width $sheetWidth -Height ($sheetHeight * $hairStyleIds.Count)
$hairDollCanvas = New-Canvas -Width ($dollWidth * $hairStyleIds.Count) -Height $dollHeight

try {
	for ($row = 0; $row -lt $rows; $row++) {
		for ($column = 0; $column -lt $columns; $column++) {
			$pose = Get-Pose -Frame $column
			$layers = Get-BodyLayers -Row $row -Pose $pose -IncludeFingers $false
			$cropHair = Get-HairLayers -Style 0 -Row $row -Pose $pose
			for ($layerIndex = 0; $layerIndex -lt $fieldLayerOrder.Count; $layerIndex++) {
				$layerId = $fieldLayerOrder[$layerIndex]
				$originX = $column * $frameWidth
				$originY = $layerIndex * $sheetHeight + $row * $frameHeight
				Draw-Rects -Canvas $fieldCanvas.Graphics -Rects $layers[$layerId] -OriginX $originX -OriginY $originY -Scale 1
				Draw-Rects -Canvas $flatCanvas.Graphics -Rects $layers[$layerId] -OriginX $originX -OriginY ($row * $frameHeight) -Scale 1
			}
			Draw-Rects -Canvas $flatCanvas.Graphics -Rects $cropHair -OriginX ($column * $frameWidth) -OriginY ($row * $frameHeight) -Scale 1
			for ($style = 0; $style -lt $hairStyleIds.Count; $style++) {
				$hair = Get-HairLayers -Style $style -Row $row -Pose $pose
				$hairOriginY = $style * $sheetHeight + $row * $frameHeight
				Draw-Rects -Canvas $hairFieldCanvas.Graphics -Rects $hair -OriginX ($column * $frameWidth) -OriginY $hairOriginY -Scale 1
			}
		}
	}

	$idlePose = Get-Pose -Frame 0
	$dollLayers = Get-BodyLayers -Row 4 -Pose $idlePose -IncludeFingers $true
	for ($layerIndex = 0; $layerIndex -lt $dollLayerOrder.Count; $layerIndex++) {
		$layerId = $dollLayerOrder[$layerIndex]
		Draw-Rects -Canvas $dollCanvas.Graphics -Rects $dollLayers[$layerId] -OriginX ($layerIndex * $dollWidth) -OriginY 0 -Scale $dollScale
	}
	for ($style = 0; $style -lt $hairStyleIds.Count; $style++) {
		$hair = Get-HairLayers -Style $style -Row 4 -Pose $idlePose
		Draw-Rects -Canvas $hairDollCanvas.Graphics -Rects $hair -OriginX ($style * $dollWidth) -OriginY 0 -Scale $dollScale
	}

	$outputs = @{
		(Join-Path $sourceDirectory 'mara_layers_field.png') = $fieldCanvas.Bitmap
		(Join-Path $sourceDirectory 'mara_layers_doll.png') = $dollCanvas.Bitmap
		(Join-Path $sourceDirectory 'mara_prototype.png') = $flatCanvas.Bitmap
		(Join-Path $sourceDirectory 'mara_hair_field.png') = $hairFieldCanvas.Bitmap
		(Join-Path $sourceDirectory 'mara_hair_doll.png') = $hairDollCanvas.Bitmap
	}
	foreach ($path in $outputs.Keys) {
		$outputs[$path].Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
		Copy-Item -LiteralPath $path -Destination (Join-Path $runtimeDirectory (Split-Path -Leaf $path)) -Force
	}
}
finally {
	foreach ($canvas in @($fieldCanvas, $dollCanvas, $flatCanvas, $hairFieldCanvas, $hairDollCanvas)) {
		$canvas.Graphics.Dispose()
		$canvas.Bitmap.Dispose()
	}
}

$paletteNames = @($palette.Keys | Sort-Object)
$metadata = [ordered]@{
	asset_id = 'sprite.actor.mara.layers'
	authorship = 'Asterfold project, generated by tools/generate_mara_layers.ps1'
	license = 'Project-owned original work'
	review_status = 'Approved for the graybox layered kit only'
	export_settings = [ordered]@{
		frame = [ordered]@{ width = $frameWidth; height = $frameHeight; columns = $columns; rows = $rows }
		ground_pivot = @(24, 60)
		directions = @('north', 'north_east', 'east', 'south_east', 'south')
		mirrored_directions = @('north_west', 'west', 'south_west')
		idle_frames = $idleFrames
		walk_frames = $walkFrames
		starter_attire = 'brown t-shirt, blue jeans, tan boots, short brown hair'
		doll_frame = [ordered]@{ width = $dollWidth; height = $dollHeight; pose = 'south_idle' }
		field_layer_order = $fieldLayerOrder
		doll_layer_order = $dollLayerOrder
		hair_style_ids = $hairStyleIds
		field_collapse = 'Finger layers are painted into their hand layer on field cards. Hair is a stacked style atlas, not a body layer.'
	}
	palette = $paletteNames
}
$metadataPath = Join-Path $sourceDirectory 'mara_layers.source.json'
$metadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $metadataPath -Encoding utf8

$prototypeMetadata = [ordered]@{
	schema_version = 1
	asset_id = 'sprite.actor.mara.prototype'
	source_file = 'mara_prototype.png'
	author = 'Asterfold project'
	authorship = 'Original project-owned prototype drawn by the Asterfold project via its deterministic PowerShell generator; no external model or source artwork was used. Since the layered kit landed, this sheet is the flattened unequipped fallback produced by the same generator.'
	license = 'Project-owned original work'
	review_status = 'Approved for M1 prototype only'
	external_sources = @()
	generation = [ordered]@{
		tool = 'game/tools/generate_mara_layers.ps1'
		model = $null
		prompt = $null
		review_status = 'approved for M1 prototype only'
	}
	export_settings = [ordered]@{
		format = 'PNG RGBA'
		sheet_size = @($sheetWidth, $sheetHeight)
		frame_size = @($frameWidth, $frameHeight)
		pixels_per_meter = 32
		filter = 'nearest'
		mipmaps = $false
	}
	frame = [ordered]@{
		width = $frameWidth
		height = $frameHeight
		columns = $columns
		rows = $rows
		directions = @('north', 'north_east', 'east', 'south_east', 'south')
		mirrored_directions = @('north_west', 'west', 'south_west')
		idle_frames = $idleFrames
		walk_frames = $walkFrames
		ground_pivot = @(24, 60)
	}
	palette = @(
		'#2A241C', '#3D2814', '#6B4423', '#8B5E3C', '#C48662', '#D7A07B', '#EDBE91',
		'#5C3A1A', '#8B5A2B', '#A6723E', '#243A5C', '#3B5A8A', '#5A7AAB',
		'#8B7355', '#C4A574', '#D4BC94', '#4A3728', '#F2E6D8', '#3A2A22'
	)
}
$prototypeMetadataPath = Join-Path $sourceDirectory 'mara_prototype.source.json'
$prototypeMetadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $prototypeMetadataPath -Encoding utf8

Write-Output "Generated layered adventurer kit in $runtimeDirectory"
