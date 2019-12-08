param(
    [string]$InputFile,
    [string]$OutputFile,
    [switch]$LineNumbers = $false
)

if(!$InputFile)
{
    Write-Host "Usage: ./Highlight-PS.ps1 -InputFile SOME_FILE_PATH [-LineNumbers]"
    exit
}
if(!$OutputFile)
{
    $OutputFile = [IO.Path]::ChangeExtension($InputFile, '.html')
}

if(![IO.Path]::IsPathRooted($InputFile)){
    $InputFile = [IO.Path]::GetFullPath((Join-Path (Get-Location) $InputFile))
}
if(![IO.Path]::IsPathRooted($OutputFile)){
    $OutputFile = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputFile))
}

$input = [IO.File]::ReadAllText($InputFile)
$output = '<figure class="highlight"><pre><code class="language-powershell" data-lang="powershell">'
if($LineNumbers)
{
    $output += '<table class="rouge-table"><tbody><tr><td class="gutter gl"><pre class="lineno">'
    $lineCount = [regex]::matches($input,”((?:\r\n)|\r|\n)”).count
    for($i = 1; $i -le $lineCount; $i++)
    {
        $output += "$i`n"
    }
    $output += '</pre></td><td class="code"><pre>'
}

$tokens = [System.Management.Automation.PsParser]::Tokenize($input, [ref]$null)
$previousTokenEnd = 0
for($i = 0; $i -lt $tokens.Count; $i++){
    $token = $tokens[$i]

    # Check for non-token whitespace
    if($token.Start -gt $previousTokenEnd)
    {
        $skippedWhitespace = $input.SubString($previousTokenEnd, $token.Start - $previousTokenEnd)
        $output += "<span class=""w"">$skippedWhitespace</span>"
    }
    $type = $token.Type
    $content = $input.SubString($token.Start, $token.Length)
    switch($type)
    {
        ([System.Management.Automation.PSTokenType]::Attribute) {$output += "<span class=""a"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::Command) {$output += "<span class=""c"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::CommandArgument) {$output += "<span class=""ca"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::Comment) {$output += "<span class=""co"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::CommandParameter) {$output += "<span class=""cp"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::GroupEnd) {$output += "<span class=""ge"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::GroupStart) {$output += "<span class=""gs"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::Keyword) {$output += "<span class=""k"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::LoopLabel) {$output += "<span class=""l"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::LineContinuation) {$output += "<span class=""lc"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::Member) {$output += "<span class=""m"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::Number) {$output += "<span class=""n"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::NewLine) {$output += "<span class=""nl"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::Operator) {$output += "<span class=""o"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::String) {$output += "<span class=""s"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::StatementSeparator) {$output += "<span class=""ss"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::Type) {$output += "<span class=""t"">$content</span>"; Break}
        ([System.Management.Automation.PSTokenType]::Variable) {$output += "<span class=""v"">$content</span>"; Break}
    }
    $previousTokenEnd = $token.Start + $token.Length
}
if($previousTokenEnd -lt $input.Length)
{
    $skippedWhitespace = $input.SubString($previousTokenEnd, $input.Length - $previousTokenEnd)
    $output += "<span class=""w"">$skippedWhitespace</span>"
}

if($LineNumbers)
{
    $output += '</pre></td></tr></tbody></table>'
}
$output += '</code></pre></figure>'

Out-File -FilePath $OutputFile -InputObject $output -Encoding UTF8NoBOM -NoClobber
