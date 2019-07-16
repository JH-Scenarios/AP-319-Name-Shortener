# Gets the Railworks directory from the registry. Thanks DanH for this. :-)
$railworksDirectory = $(Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\RailSimulator.com\RailWorks").Install_Path + '\'
$serzExeFullPath = $railworksDirectory + "serz.exe"
$ap319PreloadFolder = $railworksDirectory + "Assets\AP\Class319Pack01\Preload"

# Set working directory to the Preload folder.
Push-Location $ap319PreloadFolder

# Get the bin files.
$binFiles = Get-ChildItem -Filter "*.bin" | Select-Object -ExpandProperty BaseName

foreach($binFile in $binFiles)
{
    # Ignore this file as it's not a consist.
    if ($binFile -eq "MetaData") 
    { 
        continue; 
    }

    # Use serz.exe to convert the file to XML format.
    Start-Process $serzExeFullPath -ArgumentList """$binFile.bin""" -NoNewWindow -Wait | Out-Null

    # Load the file.
    [xml] $document = Get-Content "$($binFile).xml" -Encoding UTF8

    # Shorten the loco name in the consist list.
    $document.cBlueprintLoader.Blueprint.cConsistBlueprint.LocoName.'Localisation-cUserLocalisedString'.English.InnerText = "AP319"

    # $preloadName contains the 'long' name of the consist which will be shortened.
    $preloadName =  $document.cBlueprintLoader.Blueprint.cConsistBlueprint.DisplayName.'Localisation-cUserLocalisedString'.English.'#text'

    <#
      The name is shortened by replacing long form names with abbreviations using the Replace() function.
      You can edit this section to shorten the name as you require.
    #>
    $preloadName = $preloadName.Replace("AP Class 319", "AP319")
    $preloadName = $preloadName.Replace("Ex-First Capital Connect", "Ex-FCC")
    $preloadName = $preloadName.Replace("Ex-Southern", "Ex-SN")
    $preloadName = $preloadName.Replace("First Capital Connect", "FCC")
    $preloadName = $preloadName.Replace("Thameslink", "TL")
    $preloadName = $preloadName.Replace("London Midland", "LM")
    $preloadName = $preloadName.Replace("Northern Rail", "NT (Serco Abellio)")
    $preloadName = $preloadName.Replace("Northern", "NT (Arriva)")

    # Update the name in the XML file.
    $document.cBlueprintLoader.Blueprint.cConsistBlueprint.DisplayName.'Localisation-cUserLocalisedString'.English.InnerText = $preloadName
    
    <# 
      Must explicitly write output as UTF8 without the byte order mark (BOM) or serz.exe will fail to read it.
      Writing the file with the BOM causes serz.exe to write an empty .bin file.
    #>
    $encoding = New-Object System.Text.UTF8Encoding($false);
    $streamWriter = New-Object System.IO.StreamWriter("$pwd\$binFile.xml", $false, $encoding)
    $document.Save($streamWriter);
    $streamWriter.Close();

    # Convert the file back to .bin file.
    Start-Process $serzExeFullPath -ArgumentList """$binFile.xml""" -NoNewWindow -Wait | Out-Null
}

# Clean up folder.
Get-ChildItem -Filter "*.xml" | Remove-Item

Pop-Location
