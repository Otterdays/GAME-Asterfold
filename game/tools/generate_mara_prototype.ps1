param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$gameRoot = Split-Path -Parent $PSScriptRoot
$sourceDirectory = Join-Path $gameRoot 'art_source\characters\mara'
$runtimeDirectory = Join-Path $gameRoot 'assets\generated\characters\mara'
$sourcePath = Join-Path $sourceDirectory 'mara_prototype.png'
$runtimePath = Join-Path $runtimeDirectory 'mara_prototype.png'

New-Item -ItemType Directory -Force -Path $sourceDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $runtimeDirectory | Out-Null

$frameWidth = 48
$frameHeight = 64
$columns = 6
$rows = 5
$bitmap = [System.Drawing.Bitmap]::new($frameWidth * $columns, $frameHeight * $rows, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

$palette = @{
	Outline = [System.Drawing.ColorTranslator]::FromHtml('#263142')
	Hair = [System.Drawing.ColorTranslator]::FromHtml('#35445D')
	HairLight = [System.Drawing.ColorTranslator]::FromHtml('#52627C')
	Skin = [System.Drawing.ColorTranslator]::FromHtml('#D7A07B')
	SkinLight = [System.Drawing.ColorTranslator]::FromHtml('#EDBE91')
	Berry = [System.Drawing.ColorTranslator]::FromHtml('#8D405A')
	BerryLight = [System.Drawing.ColorTranslator]::FromHtml('#B65A70')
	Honey = [System.Drawing.ColorTranslator]::FromHtml('#E3A64B')
	Slate = [System.Drawing.ColorTranslator]::FromHtml('#46566D')
	Boot = [System.Drawing.ColorTranslator]::FromHtml('#212B3A')
	Paper = [System.Drawing.ColorTranslator]::FromHtml('#F0E2B8')
}

function Fill-Rect {
	param(
		[System.Drawing.Graphics]$Canvas,
		[System.Drawing.Color]$Color,
		[int]$X,
		[int]$Y,
		[int]$Width,
		[int]$Height
	)
	$brush = [System.Drawing.SolidBrush]::new($Color)
	try {
		$Canvas.FillRectangle($brush, $X, $Y, $Width, $Height)
	} finally {
		$brush.Dispose()
	}
}

function Draw-MaraFrame {
	param(
		[System.Drawing.Graphics]$Canvas,
		[int]$OriginX,
		[int]$OriginY,
		[int]$DirectionRow,
		[int]$FrameIndex
	)

	$walkOffsets = @(0, 0, -1, 0, 1, 0)
	$legOffsets = @(0, 0, -2, 2, 2, -2)
	$bob = $walkOffsets[$FrameIndex]
	$leg = $legOffsets[$FrameIndex]
	$centerX = $OriginX + 24
	$baseY = $OriginY + $bob

	# Legs and boots anchor every frame to the same ground line.
	Fill-Rect $Canvas $palette.Outline ($centerX - 7 + [Math]::Min($leg, 0)) ($OriginY + 49) 6 10
	Fill-Rect $Canvas $palette.Outline ($centerX + 1 + [Math]::Max($leg, 0)) ($OriginY + 49) 6 10
	Fill-Rect $Canvas $palette.Slate ($centerX - 6 + [Math]::Min($leg, 0)) ($OriginY + 49) 4 7
	Fill-Rect $Canvas $palette.Slate ($centerX + 2 + [Math]::Max($leg, 0)) ($OriginY + 49) 4 7
	Fill-Rect $Canvas $palette.Boot ($centerX - 8 + [Math]::Min($leg, 0)) ($OriginY + 56) 7 4
	Fill-Rect $Canvas $palette.Boot ($centerX + 1 + [Math]::Max($leg, 0)) ($OriginY + 56) 7 4

	# Survey coat: broad, symmetric silhouette suitable for legal mirroring.
	Fill-Rect $Canvas $palette.Outline ($centerX - 12) ($baseY + 26) 24 25
	Fill-Rect $Canvas $palette.Berry ($centerX - 10) ($baseY + 27) 20 22
	Fill-Rect $Canvas $palette.BerryLight ($centerX - 8) ($baseY + 29) 4 16
	Fill-Rect $Canvas $palette.Outline ($centerX - 15) ($baseY + 30) 5 16
	Fill-Rect $Canvas $palette.Outline ($centerX + 10) ($baseY + 30) 5 16
	Fill-Rect $Canvas $palette.Berry ($centerX - 14) ($baseY + 31) 4 13
	Fill-Rect $Canvas $palette.Berry ($centerX + 10) ($baseY + 31) 4 13

	# Head, cap, and centered survey badge.
	Fill-Rect $Canvas $palette.Outline ($centerX - 9) ($baseY + 9) 18 19
	Fill-Rect $Canvas $palette.Skin ($centerX - 7) ($baseY + 12) 14 14
	Fill-Rect $Canvas $palette.Hair ($centerX - 9) ($baseY + 7) 18 8
	Fill-Rect $Canvas $palette.HairLight ($centerX - 6) ($baseY + 6) 12 3
	Fill-Rect $Canvas $palette.Honey ($centerX - 7) ($baseY + 25) 14 4
	Fill-Rect $Canvas $palette.Outline ($centerX - 3) ($baseY + 35) 6 7
	Fill-Rect $Canvas $palette.Honey ($centerX - 2) ($baseY + 36) 4 5

	# Direction-specific face and map details. Rows: N, NE, E, SE, S.
	switch ($DirectionRow) {
		0 {
			Fill-Rect $Canvas $palette.Hair ($centerX - 7) ($baseY + 13) 14 11
			Fill-Rect $Canvas $palette.Paper ($centerX - 4) ($baseY + 30) 8 7
		}
		1 {
			Fill-Rect $Canvas $palette.Hair ($centerX - 8) ($baseY + 12) 7 13
			Fill-Rect $Canvas $palette.Outline ($centerX + 4) ($baseY + 17) 2 2
			Fill-Rect $Canvas $palette.SkinLight ($centerX + 6) ($baseY + 20) 2 3
			Fill-Rect $Canvas $palette.Paper ($centerX - 1) ($baseY + 31) 7 6
		}
		2 {
			Fill-Rect $Canvas $palette.Hair ($centerX - 8) ($baseY + 11) 8 14
			Fill-Rect $Canvas $palette.Outline ($centerX + 4) ($baseY + 17) 2 2
			Fill-Rect $Canvas $palette.SkinLight ($centerX + 7) ($baseY + 20) 2 3
			Fill-Rect $Canvas $palette.Paper ($centerX + 1) ($baseY + 31) 6 7
		}
		3 {
			Fill-Rect $Canvas $palette.Hair ($centerX - 7) ($baseY + 11) 7 10
			Fill-Rect $Canvas $palette.Outline ($centerX + 4) ($baseY + 17) 2 2
			Fill-Rect $Canvas $palette.SkinLight ($centerX + 6) ($baseY + 20) 2 3
			Fill-Rect $Canvas $palette.Paper ($centerX + 1) ($baseY + 32) 7 6
		}
		4 {
			Fill-Rect $Canvas $palette.Outline ($centerX - 5) ($baseY + 17) 2 2
			Fill-Rect $Canvas $palette.Outline ($centerX + 3) ($baseY + 17) 2 2
			Fill-Rect $Canvas $palette.SkinLight ($centerX - 2) ($baseY + 21) 4 2
			Fill-Rect $Canvas $palette.Paper ($centerX - 4) ($baseY + 31) 8 6
		}
	}
}

try {
	for ($row = 0; $row -lt $rows; $row++) {
		for ($column = 0; $column -lt $columns; $column++) {
			Draw-MaraFrame $graphics ($column * $frameWidth) ($row * $frameHeight) $row $column
		}
	}
	$bitmap.Save($sourcePath, [System.Drawing.Imaging.ImageFormat]::Png)
	Copy-Item -LiteralPath $sourcePath -Destination $runtimePath -Force
} finally {
	$graphics.Dispose()
	$bitmap.Dispose()
}

Write-Output "Generated Mara prototype sprite sheet: $runtimePath"

