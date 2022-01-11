
[![Deploy To Microsoft Cloud](./images/deploytomicrosoftcloud.svg)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fesbran%2FHealthcareApi%2Fmaster%2FhealthcareArm.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fesbran%2FHealthcareApi%2Fmaster%2Fhealthcare-portal.json)

[Back to documentation](https://github.com/microsoft/industry/tree/main/healthcare/solutions/healthcareApis)

### 1) Authorize and get token 
```powershell
Connect-AzAccount -Tenant "<<Tenant ID>>" -Subscription "<<subscription ID>>"
$fhirservice = 'https://<<Your FHIR service>>.fhir.azurehealthcareapis.com'

$token = (Get-AzAccessToken -ResourceUrl $fhirservice).token
```

### 2) Test one file
```powershell
$file = "fhir\Adolph80_Runolfsson901_89b38456-3ee1-40cb-a541-2918bda7cc84.json"
$filecontent =  Get-Content -Raw $file

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $($token)")
$headers.Add("Content-Type", "application/json")

$FhirGetPatient = Invoke-RestMethod "$fhirservice/" `
    -Method 'POST' `
    -Headers $headers `
    -Body $filecontent

    Write-Verbose $FhirGetPatient | ConvertTo-Json
```

### 3) Upload all files from Github (~5min)
```powershell
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $($token)")
$headers.Add("Content-Type", "application/json")
function DownloadFilesFromRepo {
    Param(
        [string]$Owner,
        [string]$Repository,
        [string]$Path
        )
        $baseUri = "https://api.github.com/"
        $args = "repos/$Owner/$Repository/contents/$Path"
        $wr = Invoke-WebRequest -Uri $($baseuri+$args)
        $objects = $wr.Content | ConvertFrom-Json
        $files = $objects | Where-Object {$_.type -eq "file"} | Select-Object -exp download_url
        foreach ($file in $files[0]) {
            $dlfile = Invoke-WebRequest -Uri $file
            try {

                $FhirGetPatient = Invoke-RestMethod "$fhirservice" `
                -Method 'POST' `
                -Headers $headers `
                -Body $dlfile

                Write-Verbose $file
            } catch {
                throw "Unable to download '$($file)' Patient: '$($FhirGetPatient)'"
            }
        }
    }
    DownloadFilesFromRepo -Owner 'esbran' -Repository 'HealthcareApi' -Path 'sampledata/fhir'
```

### 3) Different methods for reading the data
```powershell
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $($token)")
$headers.Add("Content-Type", "application/json")

$FhirGetMalePatients = Invoke-RestMethod "$fhirservice/Patient?gender:not=female" `
    -Method 'GET' `
    -Headers $headers
Write-Verbose  $FhirGetMalePatients

$FhirGetPatientName = Invoke-RestMethod "$fhirservice/Patient?name:exact=Espen" `
    -Method 'GET' `
    -Headers $headers
$FhirGetPatientName | ConvertTo-Json
Write-Verbose  $FhirGetPatientName | ConvertTo-Json

$FhirGetPatientId = Invoke-RestMethod "$fhirservice/Patient/9597af7fad76a04d8f13084da869131e" `
    -Method 'GET' `
    -Headers $headers
    $FhirGetPatientId | ConvertTo-Json
Write-Verbose  $FhirGetPatientId

$FhirExport = Invoke-RestMethod "$fhirservice/Patient/$export" `
    -Method 'GET' `
    -Headers $headers
    $FhirExport | ConvertTo-Json
Write-Verbose  $FhirExport 
```
