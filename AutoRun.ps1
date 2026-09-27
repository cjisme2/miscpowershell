<#
.SYNOPSIS
    Downloads a ZIP file, extracts it to the user's temp directory, and runs an executable.

.DESCRIPTION
    This script automates the download of a compressed file from a URL, extracts its contents 
    to $env:TEMP (the user's local temp directory), and then executes a specific program 
    within those extracted contents.

.NOTES
    Requires PowerShell version 5.0 or newer for Expand-Archive functionality.
#>

# ===============================================
# CONFIGURATION SECTION - MODIFY THESE VALUES
# ===============================================

# 1. Source URL of the compressed file
$DownloadUrl = "https://example.com/file.zip"

# 2. The desired destination folder for extraction (MUST be accessible by the user)
$ExtractionRootPath = Join-Path -Path $env:TEMP -ChildPath "RunmeProject"

# 3. The name of the executable and its arguments
$ExecutableName = "runme.exe"
$Arguments = "-config blah.conf"

# Define the full paths based on configuration
$DownloadFile = Join-Path -Path $ExtractionRootPath -ChildPath "downloaded_file.zip"
$ZipFile = $DownloadUrl # We use the URL, but save it locally first

# -----------------------------------------------
# END OF CONFIGURATION SECTION
# ================================================


Write-Host "--- Starting Automation Sequence ---" -ForegroundColor Cyan

# Step 1: Download the ZIP file
Write-Host "Step 1/3: Downloading file from $DownloadUrl..."

try {
    # Ensure the root extraction directory exists before downloading/extracting
    if (-not (Test-Path $ExtractionRootPath)) {
        New-Item -Path $ExtractionRootPath -ItemType Directory | Out-Null
    }

    # Use Invoke-WebRequest to download the file and save it locally
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadFile -UseSSL -ErrorAction Stop

    Write-Host "Successfully downloaded file to $DownloadFile" -ForegroundColor Green
} catch {
    Write-Error "FATAL ERROR during download. Check the URL and network connection."
    $_ | Write-Error
    Exit 1 # Exit script upon fatal download error
}


# Step 2: Extract the contents of the ZIP file
Write-Host "Step 2/3: Extracting contents to $ExtractionRootPath..."

try {
    # Expand-Archive handles the decompression and placement of all contents.
    Expand-Archive -Path $DownloadFile -DestinationPath $ExtractionRootPath -Force

    Write-Host "Successfully extracted contents." -ForegroundColor Green
} catch {
    Write-Error "FATAL ERROR during extraction. Ensure the file is a valid ZIP archive."
    $_ | Write-Error
    # Optional cleanup: If extraction fails, you might want to delete the bad zip file here.
    Remove-Item $DownloadFile -ErrorAction SilentlyContinue 
    Exit 1 # Exit script upon fatal extraction error
}


# Step 3: Run the executable and cleanup
Write-Host "Step 3/3: Running $ExecutableName with arguments '$Arguments'..."

try {
    # Construct the full path to the executable assuming it is in the extracted folder
    $FullExecutablePath = Join-Path -Path $ExtractionRootPath -ChildPath "$ExecutableName"

    if (-not (Test-Path $FullExecutablePath)) {
        Write-Error "FATAL ERROR: runme.exe not found at expected location ($FullExecutablePath)."
        Exit 1
    }

    # Use Start-Process to run the executable cleanly
    Start-Process -FilePath $FullExecutablePath -ArgumentList $Arguments -WorkingDirectory $ExtractionRootPath -Wait -NoNewWindow

    Write-Host "SUCCESS: Program execution complete." -ForegroundColor Green
} catch {
    Write-Error "ERROR executing the program: $($_.Exception.Message)"
} finally {
    # Clean up the extracted and downloaded files/folders after successful run (or failure)
    Write-Host "Starting cleanup phase..."
    
    # Remove the downloaded ZIP file first
    Remove-Item $DownloadFile -Force -ErrorAction SilentlyContinue

    # Optional: Remove the entire working folder. Be careful if you need logs!
    # Remove-Item $ExtractionRootPath -Recurse -Force 
    Write-Host "Cleanup complete."
}
