# TODO cachePath - temporarily the current dir until generation is fixed, and running via a module 
$cachePath = "C:\Users\Stuart\Source\Repos\posh-dotnet\"

function DebugMessage($message){
    if($env:POSH_DOTNET_DEBUG -eq 1){
        [System.Diagnostics.Debug]::WriteLine("PoshDotNet $message")
    }
}

function GetCommands(){
    ## TODO - find commands in current dir/path
    ## for now, hard-code to a few test commands!
    return @("compile", "publish", "restore", "run")
}
function GetCommandHelp($command){
    ## TODO - should generate help if it doesn't exist :-)
    
    $helpPath = Join-Path -Path $cachePath -ChildPath "dotnet-$command.json"
    if (Test-Path $helpPath) {
        $help = Get-Content $helpPath | ConvertFrom-Json
        return $help
    }
}

function GetValueCompletion($identifier){
    switch ($identifier){
        "<PROJECT>" {$null}
        # "<PROJECT>" {"clr", "coreclr"}
    }
}

function DotNetCompletion($line){
	$segments = @($line.Split(' ') | ?{ $_ -ne ''} | %{ $_.Trim() })
    $endsWithSpace = $line.EndsWith(" ")
    
    ## TODO add support for "dotnet help xx" completion
    
    if (($segments.Length -eq 1 -and $endsWithSpace) -or ($segments.Length -eq 2 -and -not $endsWithSpace)){
        # "dotnet " or "dotnet xx"
        # complete command
        $command = $segments[1]
        return GetCommands | Where-Object { $_.StartsWith($command) }
    } elseif ($segments.Length -ge 2){
        ## TODO - if args length >2 then complete args/options
        $command = $segments[1]
        $commandHelp = GetCommandHelp $command
        if ($commandHelp -ne $null){
            $argumentIndex = $segments.Length - 3 # "dotnet command " is the prefix
            if($endsWithSpace){
                $argumentIndex++ # space indicates that we're starting the next argument 
                $currentArgumentValue = ""
            } else {
                $currentArgumentValue = $segments[$segments.Length-1];
            }
            
            ## TODO - check within the argument count!!
            ## TODO - handle options!!
    
            ## TODO do something meaningful to complete!! 
            $currentArgument = $commandHelp.arguments[$argumentIndex]
            $items = GetValueCompletion $currentArgument.name
            if ($items -eq $null){
                return $null
            } else {
                return $items | ?{ $_.StartsWith($currentArgumentValue)}
            }
        }
    }
}

function Fallback($line, $lastWord){
    if (Test-Path Function:\DotNetTabExpansionBackup) { 
        DotNetTabExpansionBackup $line $lastWord 
    }
}

DebugMessage "Installing..."
if(-not (Test-Path Function:\DotNetTabExpansionBackup)){

    if (Test-Path Function:\TabExpansion) {
		DebugMessage "\tbackup previous TabExpansion"
        Rename-Item Function:\TabExpansion DotNetTabExpansionBackup
    }

	DebugMessage "\tInstalling TabExpansion hook"
    function TabExpansion($line, $lastWord) {
       $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()
       DebugMessage "TabExpansion: $lastBlock"

       switch -Regex ($lastBlock) {
            "^dotnet (.*)" { 
                $response = DotNetCompletion $lastBlock
                if($response -eq $null) {
                    DebugMessage "TabExpansion: got null - falling back"
                    $response = Fallback $line $lastWord
                }
                $response
            }

            # Fall back on existing tab expansion
            default { Fallback $line $lastWord }
       }
    }
}