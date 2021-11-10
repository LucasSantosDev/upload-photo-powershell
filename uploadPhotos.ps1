$logFile = "$(Get-Location)\$(Get-Date -Format "dd-MM-yyyy").log"

$baseUrl = "https://ENDPOINT_API"

$pathImages = "PATH_IMAGES" # Example: C:\Users\Photos

Function WriteLog
{
   Param ([string]$logString)

   Add-content $logFile -value $logString

   Write-Host $logString
}

Function GetFiles
{
	# GETTING RANGE OF DATE IN FILES TO MAKE UPLOAD
	$today = Get-Date
	$todayLessThreeDays = (Get-Date $today).AddDays(-3)

	WriteLog ">>>> LOG FILE $($logFile) <<<<"
	WriteLog ">>>> FIND FILES IN PATH $($pathImages) <<<<"
	WriteLog ">>>> FIND FOR FILES BETWEEN $($todayLessThreeDays) AND $($today) <<<<"

	# GETTING FILES INTO PATH
	return Get-ChildItem $pathImages -File -Include *.tif, *.bmp, *.gif, *.png, *.jpeg, *.jpe, *.jfif, *.jpg -Recurse | 
		Where-Object { $_.LastWriteTime -ge $todayLessThreeDays -and $_.LastWriteTime -le $today } | 
		select-Object FullName, LastWriteTime
}

Function CheckIfPhotoExists([string]$fileNameId)
{
    ## TODO :: IT's NECESSARY CHANGE TO ENDPOINT TO CHECK IF EXISTS IMAGE
	$uri = "$($baseUrl)/image-show/$($fileNameId)"

	$result = Invoke-WebRequest -uri $uri -method GET

    ## TODO :: IT's NECESSARY CHANGE TEXT "body" TO SOMETHING IN YOUR RESPONSE WHEN SUCCESS
	if($result.Content -like '*body*') {
		WriteLog "=============================="
		WriteLog ">>>> IMAGE ALREADY EXISTS <<<<"
		WriteLog "=============================="
		return $true;
	}

	return $false;
}

Function UploadPhoto([string]$file)
{
	$nameFileWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($file)

    ## TODO :: IT's NECESSARY CHANGE TO ENDPOINT TO UPLOAD PHOTO
	$uri = "$($baseUrl)/upload-photo/$($nameFileWithoutExt)"

	WriteLog ">>>> URI $($uri) <<<<"
	WriteLog ">>>> FILE $($file) <<<<"

	$imageExists = CheckIfPhotoExists($nameFileWithoutExt)

	if (!$imageExists) {
        ## TODO :: IT's NECESSARY CHANGE BODY OF REQUEST
		$body = @{"photo" = [convert]::ToBase64String((Get-Content -path $file -Encoding byte))} | ConvertTo-Json

		$result = Invoke-RestMethod -uri $uri -method PUT -ContentType "application/json" -body $body

		WriteLog ">>>> RESULT $($result) <<<<"
	}
}

Function Main
{
	WriteLog ">>>> INIT <<<<"

	try {
		$files = GetFiles

		foreach ($file in $files)
		{
			WriteLog "======================================="
			UploadPhoto($file.FullName)
			WriteLog "======================================="
		}
	}
	catch {
		WriteLog ">>>> ERROR FOUNDED <<<<"
		WriteLog $_
	}

	WriteLog ">>>> END <<<<"
}

Main
