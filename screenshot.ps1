# =============================================
# CONFIGURATION SECTION
# =============================================

# IMPORTANT: Using the user profile guarantees write permissions.
$SaveFolder = "$env:USERPROFILE\Desktop\AutoScreenshots"

# Use a folder within your Documents/Desktop path for reliability.
# If you prefer, you can use: $SaveFolder = "C:\Users\YourUsername\Desktop\AutoScreenshots" 

$IntervalSeconds = 300 # 5 minutes
$FileExtension = ".png"

# =============================================
# SETUP AND FUNCTIONS
# =============================================

Function -Name Get-Screenshot {
    [CmdletBinding()]
    param()

    # Check if the save folder exists, and create it if not.
    if (-not (Test-Path $SaveFolder)) {
        Write-Host "Creating directory: $SaveFolder"
        New-Item -Path $SaveFolder -ItemType Directory | Out-Null
    }

    # Use .NET classes to handle the screenshot capture and image export.
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        # 1. Define the screen dimensions (full screen)
        $Screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

        # 2. Create a bitmap object to hold the image data
        $Image = New-Object System.Drawing.Bitmap $Screen.Size

        # 3. Create a graphics object and copy the screen content into it
        $Graphics = [System.Drawing.Graphics]::FromImage($Image)
        $Graphics.CopyFromScreen($Screen.Location, [System.Drawing.Point]::Empty, [System.Drawing.Size]::new($Screen.Width, $Screen.Height))

        # 4. Generate a unique filename using a timestamp
        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $FileName = "$($Timestamp)_Screenshot$FileExtension"
        $FilePath = Join-Path -Path $SaveFolder -ChildPath $FileName

        # 5. Save the image file
        $Image.Save($FilePath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        Write-Host "SUCCESS: Screenshot saved to $FilePath" -ForegroundColor Green

    } catch {
        Write-Error "An error occurred during screenshot capture: $($_.Exception.Message)"
    } finally {
        # Cleanup resources to prevent memory leaks
        if ($Image) {$Image.Dispose()}
    }
}

# =============================================
# MAIN LOOP EXECUTION
# =============================================

Write-Host "--- Screenshot Automation Started ---" -ForegroundColor Yellow
Write-Host "Saving screenshots to: $SaveFolder"
Write-Host "Interval set to $($IntervalSeconds / 60) minutes."

while ($true) {
    # Execute the screenshot routine
    Get-Screenshot
    
    # Wait for the defined interval before looping again
    Write-Host "Waiting $IntervalSeconds seconds..."
    Start-Sleep -Seconds $IntervalSeconds
}

# Note: The script will run indefinitely until you manually stop it (Ctrl+C).
#powershell.exe -File .\screenshot.ps1
