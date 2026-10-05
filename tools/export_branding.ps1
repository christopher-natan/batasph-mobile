# Re-export the approved raster masters to platform asset sizes.
# Artwork is authored with image generation; this script only sizes and packages it.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$brandRoot = Split-Path -Parent $PSScriptRoot
$mark = [System.Drawing.Bitmap]::new((Join-Path $brandRoot 'assets/branding/batasph_balance_mark_master.png'))
$icon = [System.Drawing.Bitmap]::new((Join-Path $brandRoot 'assets/branding/batasph_balance_icon_master.png'))
$forest = $icon.GetPixel(0, 0)
$ivory = [System.Drawing.ColorTranslator]::FromHtml('#F5F1EA')
$exports = [System.Collections.Generic.List[object]]::new()

function Export-BrandImage {
    param(
        [System.Drawing.Image]$Source,
        [int]$Size,
        [string]$RelativePath,
        [double]$Scale = 1,
        [System.Drawing.Color]$Background = [System.Drawing.Color]::Transparent,
        [switch]$NoAlpha
    )
    $format = if ($NoAlpha) { [System.Drawing.Imaging.PixelFormat]::Format24bppRgb } else { [System.Drawing.Imaging.PixelFormat]::Format32bppArgb }
    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, $format)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear($Background)
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        if ($null -ne $Source) {
            $drawSize = [int][Math]::Round($Size * $Scale)
            $offset = [int][Math]::Round(($Size - $drawSize) / 2)
            $rect = [System.Drawing.Rectangle]::new($offset, $offset, $drawSize, $drawSize)
            $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
            try {
                $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
                $graphics.DrawImage($Source, $rect, 0, 0, $Source.Width, $Source.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
            } finally { $attributes.Dispose() }
        }
        $destination = Join-Path $brandRoot $RelativePath
        [System.IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
        $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
        $exports.Add([PSCustomObject]@{path=$RelativePath;size=$Size;opaque=($Background.A -eq 255);noAlpha=[bool]$NoAlpha})
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

try {
    foreach ($path in @('assets/branding/batasph_logo_mark.png', 'assets/branding/batasph_logo_mark_1024.png')) {
        Export-BrandImage $mark 1024 $path
    }
    Export-BrandImage $mark 512 'assets/images/logo.png'
    foreach ($path in @('assets/branding/batasph_app_icon_master.png', 'assets/branding/batasph_app_icon_1024.png')) {
        Export-BrandImage $icon 1024 $path -Background $forest
    }
    foreach ($path in @('assets/branding/batasph_play_store_512.png', 'docs/play-store/app-icon-512.png')) {
        Export-BrandImage $icon 512 $path -Background $forest
    }

    $densities = @(@('mdpi',1), @('hdpi',1.5), @('xhdpi',2), @('xxhdpi',3), @('xxxhdpi',4))
    foreach ($density in $densities) {
        $name = $density[0]
        $factor = $density[1]
        Export-BrandImage $icon ([int](48*$factor)) "android/app/src/main/res/mipmap-$name/ic_launcher.png" -Background $forest
        # The icon artwork is ~75% wide in its master. 72% gives ~54% coverage
        # of the 108dp adaptive layer, inside the central 66dp safe region.
        Export-BrandImage $icon ([int](108*$factor)) "android/app/src/main/res/drawable-$name/ic_launcher_foreground.png" -Scale 0.72 -Background $forest
        Export-BrandImage $mark ([int](108*$factor)) "android/app/src/main/res/drawable-$name/ic_launcher_monochrome.png" -Scale 0.58
        Export-BrandImage $mark ([int](250*$factor)) "android/app/src/main/res/drawable-$name/splash.png" -Scale 0.56
        foreach ($prefix in @('drawable','drawable-night')) {
            Export-BrandImage $mark ([int](288*$factor)) "android/app/src/main/res/$prefix-$name/android12splash.png" -Scale 0.5
        }
    }
    foreach ($path in @('android/app/src/main/res/drawable/background.png','android/app/src/main/res/drawable-v21/background.png','ios/Runner/Assets.xcassets/LaunchBackground.imageset/background.png')) {
        Export-BrandImage $null 1 $path -Background $ivory
    }

    $catalog = Get-Content -Raw (Join-Path $brandRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') | ConvertFrom-Json
    foreach ($entry in $catalog.images) {
        $points = [double]::Parse(($entry.size -split 'x')[0], [Globalization.CultureInfo]::InvariantCulture)
        $scale = [int]($entry.scale -replace 'x','')
        Export-BrandImage $icon ([int]($points*$scale)) ("ios/Runner/Assets.xcassets/AppIcon.appiconset/" + $entry.filename) -Background $forest -NoAlpha
    }
    Export-BrandImage $mark 250 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png' -Scale 0.56
    Export-BrandImage $mark 500 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png' -Scale 0.56
    Export-BrandImage $mark 750 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png' -Scale 0.56
    foreach ($size in @(192,512)) {
        Export-BrandImage $icon $size "web/icons/Icon-$size.png" -Background $forest
        Export-BrandImage $icon $size "web/icons/Icon-maskable-$size.png" -Scale 0.84 -Background $forest
    }
    Export-BrandImage $icon 32 'web/favicon.png' -Background $forest
    foreach ($scale in @(1,2,3,4)) {
        foreach ($mode in @('light','dark')) {
            Export-BrandImage $mark (250*$scale) "web/splash/img/$mode-${scale}x.png" -Scale 0.56
        }
    }
    $exports | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $brandRoot 'assets/branding/exports.json')
    Write-Output ("Exported {0} brand assets." -f $exports.Count)
} finally {
    $mark.Dispose()
    $icon.Dispose()
}

