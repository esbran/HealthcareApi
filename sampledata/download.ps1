#Connect-AzAccount -Tenant "<Tenant ID >" -Subscription "<subscription ID>"

$token = (Get-AzAccessToken -ResourceUrl $fhirservice).token

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $($token)")
$headers.Add("Content-Type", "application/json")
function DownloadFilesFromRepo {
    Param(
        [string]$Owner,
        [string]$Repository,
        [string]$Path,
        [string]$fhirservice
        )
        $baseUri = "https://api.github.com/"
        $wr = Invoke-WebRequest -Uri $($baseuri+$args)
        $objects = $wr.Content | ConvertFrom-Json
        $files = $objects | Where-Object {$_.type -eq "file"} | Select-Object -exp download_url
        $directories = $objects | Where-Object {$_.type -eq "dir"}
        $directories | ForEach-Object {
            DownloadFilesFromRepo -Owner $Owner -Repository $Repository -Path $_.path -DestinationPath $($DestinationPath+$_.name)
        }
        foreach ($file in $files[0]) {
            $dlfile = Invoke-WebRequest -Uri $file
            try {

                $FhirGetPatient = Invoke-RestMethod "$fhirservice/" `
                -Method 'POST' `
                -Headers $headers `
                -Body $dlfile

                Write-Verbose $file
            } catch {
                throw "Unable to download '$($file)' Patient: '$($FhirGetPatient)'"
            }
        }
    }
    DownloadFilesFromRepo -Owner 'esbran' -Repository 'CatHealthAPI' -Path 'sampledata/fhir/' -fhirservice 'https://eshealthapi-espenhealthfhir.fhir.azurehealthcareapis.com'
