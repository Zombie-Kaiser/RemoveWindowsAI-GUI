param()

$exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$script:runningCompiled = $exePath -notlike '*powershell.exe'
$script:rootDir = if ($script:runningCompiled) { Split-Path -Parent $exePath } else { $PSScriptRoot }

if (-not $script:runningCompiled -and $PSVersionTable.PSVersion.Major -ge 6) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    exit
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ($script:runningCompiled) {
        Start-Process $exePath -Verb RunAs
    }
    else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    }
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$script:embeddedMainScriptB64 = '__EMBEDDED_MAIN_B64__'

try { Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue } catch {}

$mainScript = Join-Path $script:rootDir 'RemoveWindowsAi.ps1'
$hasEmbedded = $script:embeddedMainScriptB64 -and $script:embeddedMainScriptB64 -ne '__EMBEDDED_MAIN_B64__'

if (!$hasEmbedded -and !(Test-Path $mainScript)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Required file not found: RemoveWindowsAi.ps1`n`nKeep it in the same folder as this program.",
        'Missing File',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    exit 1
}

if ($hasEmbedded) {
    try {
        $mainText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($script:embeddedMainScriptB64))
        $mainText = $mainText.TrimStart([char]0xFEFF)
        $mainBlock = [scriptblock]::Create($mainText)
        . $mainBlock -loadFunctionsOnly
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to load embedded main script: $($_.Exception.Message)",
            'Load Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        exit 1
    }
}
else {
    . $mainScript -loadFunctionsOnly
}

$langFile = Join-Path $script:rootDir 'RemoveWindowsAI-GUI.lang'
$script:lang = 'en'
if (Test-Path $langFile) {
    $saved = (Get-Content $langFile -Raw -ErrorAction SilentlyContinue)
    if ($saved) { $saved = $saved.Trim() }
    if ($saved -eq 'en' -or $saved -eq 'zh') { $script:lang = $saved }
}
elseif ((Get-UICulture).Name -like 'zh*') {
    $script:lang = 'zh'
}

$script:strings = @{
    en = @{
        WindowTitle       = 'Remove Windows AI'
        Title             = 'Remove Windows AI'
        ForkBy            = 'Fork by Zombie-Kaiser - original by zoicware'
        LanguageLabel     = 'Language'
        SectionRemoval    = 'AI Removal Options'
        SectionClassic    = 'Install Classic Windows Apps'
        RevertMode        = 'Revert Mode:'
        BackupMode        = 'Backup Mode:'
        DesktopShortcut   = 'Desktop Shortcut'
        StartMenuShortcut = 'Start Menu Shortcut'
        Cancel            = 'Cancel'
        Apply             = 'Apply'
        WarningTooltip    = 'Warning: This option may break Windows Update'
        InfoAria          = 'More information about {0}'
        InfoAriaHelp      = 'Opens a dialog describing this option'
        NoOptions         = 'No options selected.'
        NoOptionsTitle    = 'Nothing to Process'
        ProgressTitle     = 'Processing...'
        ProgressInit      = 'Initializing...'
        ProgressExecuting = 'Executing: {0}'
        ProgressShortcuts = 'Creating shortcuts...'
        ProgressDone      = 'Completed successfully!'
        DoneMsg           = "AI removal process completed successfully!`n`nWould you like to restart your computer now to ensure all changes take effect?"
        DoneTitle         = 'Process Complete'
        ErrorTitle        = 'Error'
        ErrorOccurred     = 'An error occurred: {0}'
        RevertInfo        = 'Revert Mode will undo changes made by this tool, restoring AI features and settings to their original state. Selected options above will be reverted/enabled when this mode is selected.'
        BackupInfo        = 'Backup Mode keeps necessary files in your User directory allowing revert mode to work properly, use this option while removing AI if you would like to fully revert the removal process.'
        ShortcutInfo      = 'Creates a shortcut that runs the latest version of this script from GitHub.'
        RevertModeTitle   = 'Revert Mode'
        BackupModeTitle   = 'Backup Mode'
        ShortcutTitle     = 'Shortcut Options'
        GitHubTooltip     = 'Open the Zombie-Kaiser RemoveWindowsAI fork repository'
        DiscordTooltip    = 'Join the Zoicware Discord'
        'opt_Disable-Registry-Keys'          = 'Disable Registry Keys'
        'opt_Prevent-AI-Package-Reinstall'   = 'Prevent AI Package Reinstall'
        'opt_Disable-Copilot-Policies'       = 'Disable Copilot Policies'
        'opt_Remove-AI-Appx-Packages'        = 'Remove AI Appx Packages'
        'opt_Remove-Recall-Optional-Feature' = 'Remove Recall Optional Feature'
        'opt_Remove-AI-CBS-Packages'         = 'Remove AI CBS Packages'
        'opt_Remove-AI-Files'                = 'Remove AI Files'
        'opt_Hide-AI-Components'             = 'Hide AI Components'
        'opt_Disable-Notepad-Rewrite'        = 'Disable Notepad Rewrite'
        'opt_Remove-WindowsAI-Tasks'         = 'Remove Windows AI Tasks'
        'opt_Update-Cleanup-Check'           = 'Update Cleanup Check'
        'opt_Disable-DefenderAI'             = 'Disable Defender AI'
        'opt_Install-Classic-Photoviewer'    = 'Install Classic Photoviewer'
        'opt_Install-Classic-Mspaint'        = 'Install Classic Mspaint'
        'opt_Install-Classic-SnippingTool'   = 'Install Classic SnippingTool'
        'opt_Install-Classic-Notepad'        = 'Install Classic Notepad'
        'opt_Install-Photos-Legacy'          = 'Install Photos Legacy'
        'desc_Disable-Registry-Keys'          = 'Disables Copilot and Recall through registry modifications, including Windows Search integration and Edge Copilot features. Also disables AI image creator in Paint and various AI-related privacy settings.'
        'desc_Prevent-AI-Package-Reinstall'   = 'Installs a custom Windows Update Package to prevent Windows Update and DISM from reinstalling AI packages.'
        'desc_Disable-Copilot-Policies'       = 'Disables Copilot policies in the Windows integrated services region policy JSON file by setting their default state to disabled.'
        'desc_Remove-AI-Appx-Packages'        = 'Removes AI-related AppX packages including Copilot, AIX, CoreAI, and various WindowsWorkload AI components using advanced removal techniques.'
        'desc_Remove-Recall-Optional-Feature' = 'Removes the Recall optional Windows feature completely from the system, including payload removal.'
        'desc_Remove-AI-CBS-Packages'         = 'Removes additional hidden AI packages from Component Based Servicing (CBS) by unhiding them and forcing removal.'
        'desc_Remove-AI-Files'                = 'Removes AI-related files from SystemApps, WindowsApps, and other system directories. Also removes machine learning DLLs and Copilot installers.'
        'desc_Hide-AI-Components'             = 'Hides AI components in Windows Settings by modifying the SettingsPageVisibility policy to prevent user access to AI settings.'
        'desc_Disable-Notepad-Rewrite'        = 'Disables the AI Rewrite feature in Windows Notepad through registry modifications and group policy settings.'
        'desc_Remove-WindowsAI-Tasks'         = 'Removes Windows AI scheduled tasks from Task Scheduler to prevent AI data collection processes from running.'
        'desc_Update-Cleanup-Check'           = 'Creates a silent scheduled task to run at log-on to check if Windows has been updated... if it has then the script will cleanup newly installed AI features'
        'desc_Disable-DefenderAI'             = 'Disables Windows Defender AI Platform Host process and features.'
        'desc_Install-Classic-Photoviewer'    = 'Installs the classic Windows Photo Viewer from Windows 7/8, allowing you to view images with the traditional viewer instead of the modern Photos app.'
        'desc_Install-Classic-Mspaint'        = 'Installs the classic Microsoft Paint application from older Windows versions.'
        'desc_Install-Classic-SnippingTool'   = 'Installs the classic Snipping Tool, replacing the modern Snip & Sketch app.'
        'desc_Install-Classic-Notepad'        = 'Installs the classic Notepad from Windows 10, replacing the modern uwp version.'
        'desc_Install-Photos-Legacy'          = 'Installs the legacy Windows Photos app from the Microsoft Store.'
    }
    zh = @{
        WindowTitle       = '移除 Windows AI'
        Title             = '移除 Windows AI'
        ForkBy            = 'Zombie-Kaiser 维护的分支 - 原作者 zoicware'
        LanguageLabel     = '语言'
        SectionRemoval    = 'AI 移除选项'
        SectionClassic    = '安装经典 Windows 应用'
        RevertMode        = '还原模式：'
        BackupMode        = '备份模式：'
        DesktopShortcut   = '桌面快捷方式'
        StartMenuShortcut = '开始菜单快捷方式'
        Cancel            = '取消'
        Apply             = '应用'
        WarningTooltip    = '警告：此选项可能导致 Windows 更新出现问题'
        InfoAria          = '关于“{0}”的更多信息'
        InfoAriaHelp      = '打开说明此选项的对话框'
        NoOptions         = '未选择任何选项。'
        NoOptionsTitle    = '没有可处理的任务'
        ProgressTitle     = '正在处理...'
        ProgressInit      = '正在初始化...'
        ProgressExecuting = '正在执行：{0}'
        ProgressShortcuts = '正在创建快捷方式...'
        ProgressDone      = '全部完成！'
        DoneMsg           = "AI 移除过程已成功完成！`n`n是否立即重启计算机以确保所有更改生效？"
        DoneTitle         = '处理完成'
        ErrorTitle        = '错误'
        ErrorOccurred     = '发生错误：{0}'
        RevertInfo        = '还原模式将撤销此工具所做的更改，把 AI 功能和设置恢复到原始状态。选择此模式后，上方选中的选项将被还原/重新启用。'
        BackupInfo        = '备份模式会在用户目录中保留必要文件，使还原模式可以正常工作。如果想完全还原移除过程，请在移除 AI 时使用此选项。'
        ShortcutInfo      = '创建一个快捷方式，用于从 GitHub 运行最新版本的脚本。'
        RevertModeTitle   = '还原模式'
        BackupModeTitle   = '备份模式'
        ShortcutTitle     = '快捷方式选项'
        GitHubTooltip     = '打开 Zombie-Kaiser 的 RemoveWindowsAI 分支仓库'
        DiscordTooltip    = '加入 Zoicware Discord'
        'opt_Disable-Registry-Keys'          = '禁用注册表项'
        'opt_Prevent-AI-Package-Reinstall'   = '阻止 AI 包重新安装'
        'opt_Disable-Copilot-Policies'       = '禁用 Copilot 策略'
        'opt_Remove-AI-Appx-Packages'        = '移除 AI Appx 包'
        'opt_Remove-Recall-Optional-Feature' = '移除 Recall 可选功能'
        'opt_Remove-AI-CBS-Packages'         = '移除 CBS AI 包'
        'opt_Remove-AI-Files'                = '移除 AI 文件'
        'opt_Hide-AI-Components'             = '隐藏 AI 组件'
        'opt_Disable-Notepad-Rewrite'        = '禁用记事本重写'
        'opt_Remove-WindowsAI-Tasks'         = '移除 AI 计划任务'
        'opt_Update-Cleanup-Check'           = '更新清理检查'
        'opt_Disable-DefenderAI'             = '禁用 Defender AI'
        'opt_Install-Classic-Photoviewer'    = '安装经典照片查看器'
        'opt_Install-Classic-Mspaint'        = '安装经典画图'
        'opt_Install-Classic-SnippingTool'   = '安装经典截图工具'
        'opt_Install-Classic-Notepad'        = '安装经典记事本'
        'opt_Install-Photos-Legacy'          = '安装照片旧版'
        'desc_Disable-Registry-Keys'          = '通过修改注册表禁用 Copilot 和 Recall，包括 Windows 搜索集成和 Edge 中的 Copilot 功能，同时禁用画图中的 AI 图像创建器及多项 AI 相关隐私设置。'
        'desc_Prevent-AI-Package-Reinstall'   = '安装自定义 Windows 更新程序包，防止 Windows 更新和 DISM 重新安装 AI 程序包。'
        'desc_Disable-Copilot-Policies'       = '通过将默认状态设置为禁用，在 Windows 集成服务区域策略 JSON 文件中禁用 Copilot 相关策略。'
        'desc_Remove-AI-Appx-Packages'        = '使用高级移除技术移除 AI 相关的 AppX 程序包，包括 Copilot、AIX、CoreAI 以及各种 WindowsWorkload AI 组件。'
        'desc_Remove-Recall-Optional-Feature' = '从系统中完全移除 Recall 可选 Windows 功能，包括有效负载。'
        'desc_Remove-AI-CBS-Packages'         = '通过取消隐藏并强制移除的方式，从组件服务 (CBS) 中移除其他隐藏的 AI 程序包。'
        'desc_Remove-AI-Files'                = '从 SystemApps、WindowsApps 及其他系统目录中移除 AI 相关文件，同时删除机器学习 DLL 和 Copilot 安装程序。'
        'desc_Hide-AI-Components'             = '通过修改 SettingsPageVisibility 策略隐藏 Windows 设置中的 AI 组件，阻止用户访问 AI 设置页面。'
        'desc_Disable-Notepad-Rewrite'        = '通过修改注册表和组策略设置，禁用 Windows 记事本中的 AI 重写功能。'
        'desc_Remove-WindowsAI-Tasks'         = '从任务计划程序中移除 Windows AI 计划任务，防止 AI 数据收集进程运行。'
        'desc_Update-Cleanup-Check'           = '创建一个在登录时运行的静默计划任务，检查 Windows 是否已更新；如果已更新，脚本将清理新安装的 AI 功能。'
        'desc_Disable-DefenderAI'             = '禁用 Windows Defender AI 平台宿主进程及相关功能。'
        'desc_Install-Classic-Photoviewer'    = '安装来自 Windows 7/8 的经典 Windows 照片查看器，使用传统查看器代替现代“照片”应用查看图片。'
        'desc_Install-Classic-Mspaint'        = '安装来自旧版 Windows 的经典 Microsoft 画图应用。'
        'desc_Install-Classic-SnippingTool'   = '安装经典截图工具，替换现代的截图和草图应用。'
        'desc_Install-Classic-Notepad'        = '安装来自 Windows 10 的经典记事本，替换现代 UWP 版本。'
        'desc_Install-Photos-Legacy'          = '从 Microsoft 商店安装旧版 Windows 照片应用。'
    }
}

function T {
    param([string]$key)
    return [string]$script:strings[$script:lang][$key]
}

$script:removalFunctions = @(
    @{ Func = 'Disable-Registry-Keys';          Checked = $true;  Warning = $false }
    @{ Func = 'Prevent-AI-Package-Reinstall';   Checked = $false; Warning = $true }
    @{ Func = 'Disable-Copilot-Policies';       Checked = $true;  Warning = $false }
    @{ Func = 'Remove-AI-Appx-Packages';        Checked = $true;  Warning = $false }
    @{ Func = 'Remove-Recall-Optional-Feature'; Checked = $true;  Warning = $false }
    @{ Func = 'Remove-AI-CBS-Packages';         Checked = $false; Warning = $true }
    @{ Func = 'Remove-AI-Files';                Checked = $false; Warning = $true }
    @{ Func = 'Hide-AI-Components';             Checked = $true;  Warning = $false }
    @{ Func = 'Disable-Notepad-Rewrite';        Checked = $true;  Warning = $false }
    @{ Func = 'Remove-WindowsAI-Tasks';         Checked = $true;  Warning = $false }
    @{ Func = 'Update-Cleanup-Check';           Checked = $true;  Warning = $false }
    @{ Func = 'Disable-DefenderAI';             Checked = $true;  Warning = $false }
)

$script:classicFunctions = @(
    @{ Func = 'Install-Classic-Photoviewer';  Checked = $false; Warning = $false }
    @{ Func = 'Install-Classic-Mspaint';      Checked = $false; Warning = $false }
    @{ Func = 'Install-Classic-SnippingTool'; Checked = $false; Warning = $false }
    @{ Func = 'Install-Classic-Notepad';      Checked = $false; Warning = $false }
    @{ Func = 'Install-Photos-Legacy';        Checked = $false; Warning = $false }
)

$script:allFunctions = @($script:removalFunctions + $script:classicFunctions | ForEach-Object { $_.Func })

$script:checkboxes = @{}
$script:optionLabels = @{}
$script:uiTextRegistry = New-Object System.Collections.ArrayList

function Register-UiText {
    param($Control, [string]$Key, [string]$Property = 'Text', [string]$Func = '')
    [void]$script:uiTextRegistry.Add(@{ Control = $Control; Key = $Key; Property = $Property; Func = $Func })
}

function Update-UiLanguage {
    foreach ($entry in $script:uiTextRegistry) {
        switch ($entry.Property) {
            'Text'    { $entry.Control.Text = T $entry.Key }
            'Title'   { $entry.Control.Title = T $entry.Key }
            'ToolTip' { $entry.Control.ToolTip = T $entry.Key }
            'Aria' {
                if ($entry.Func) {
                    [System.Windows.Automation.AutomationProperties]::SetName($entry.Control, ((T 'InfoAria') -f (T "opt_$($entry.Func)")))
                }
                else {
                    [System.Windows.Automation.AutomationProperties]::SetName($entry.Control, (T $entry.Key))
                }
            }
            'Help' { [System.Windows.Automation.AutomationProperties]::SetHelpText($entry.Control, (T $entry.Key)) }
        }
    }
    foreach ($func in $script:allFunctions) {
        $script:optionLabels[$func].Text = T "opt_$func"
    }
}

function Save-Language {
    param([string]$lang)
    try {
        [System.IO.File]::WriteAllText($langFile, $lang, [System.Text.Encoding]::ASCII)
    }
    catch { }
}

$roundButtonTemplate = @'
<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button">
    <Border Background="{TemplateBinding Background}"
            BorderBrush="{TemplateBinding BorderBrush}"
            BorderThickness="{TemplateBinding BorderThickness}"
            CornerRadius="__CORNER__">
        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
    </Border>
</ControlTemplate>
'@

function New-RoundButton {
    param(
        [double]$Width,
        [double]$Height,
        [double]$CornerRadius,
        [string]$BackgroundHex,
        [string]$Content,
        [double]$FontSize = 14
    )
    $btn = New-Object System.Windows.Controls.Button
    $btn.Width = $Width
    $btn.Height = $Height
    $btn.FontSize = $FontSize
    $btn.Foreground = [System.Windows.Media.Brushes]::White
    $btn.BorderBrush = [System.Windows.Media.Brushes]::Transparent
    $btn.BorderThickness = 0
    $btn.Cursor = 'Hand'
    $btn.Background = New-Object System.Windows.Media.SolidColorBrush(([System.Windows.Media.ColorConverter]::ConvertFromString($BackgroundHex)))
    $btn.Template = [System.Windows.Markup.XamlReader]::Parse($roundButtonTemplate -replace '__CORNER__', [string]$CornerRadius)
    if ($Content) { $btn.Content = $Content }
    return $btn
}

$toggleStyleXaml = @'
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Style x:Key="CleanToggleStyle" TargetType="{x:Type ToggleButton}">
        <Setter Property="Background" Value="Transparent"/>
        <Setter Property="BorderBrush" Value="Transparent"/>
        <Setter Property="BorderThickness" Value="0"/>
        <Setter Property="Width" Value="40"/>
        <Setter Property="Height" Value="24"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Focusable" Value="True"/>
        <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="{x:Type ToggleButton}">
                    <Grid>
                        <Border x:Name="SwitchTrack" Width="40" Height="24" Background="#E5E5E7" CornerRadius="12" BorderThickness="0">
                            <Border x:Name="SwitchThumb" Width="20" Height="20" Background="White" CornerRadius="10" HorizontalAlignment="Left" VerticalAlignment="Center" Margin="2,0,0,0">
                                <Border.Effect>
                                    <DropShadowEffect Color="#00000040" Direction="270" ShadowDepth="1" BlurRadius="3" Opacity="0.4"/>
                                </Border.Effect>
                                <Border.RenderTransform>
                                    <TranslateTransform x:Name="ThumbTransform" X="0"/>
                                </Border.RenderTransform>
                            </Border>
                        </Border>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsChecked" Value="True">
                            <Trigger.EnterActions>
                                <BeginStoryboard>
                                    <Storyboard>
                                        <DoubleAnimation Storyboard.TargetName="ThumbTransform" Storyboard.TargetProperty="X" To="16" Duration="0:0:0.2"/>
                                        <ColorAnimation Storyboard.TargetName="SwitchTrack" Storyboard.TargetProperty="Background.Color" To="#34C759" Duration="0:0:0.2"/>
                                    </Storyboard>
                                </BeginStoryboard>
                            </Trigger.EnterActions>
                            <Trigger.ExitActions>
                                <BeginStoryboard>
                                    <Storyboard>
                                        <DoubleAnimation Storyboard.TargetName="ThumbTransform" Storyboard.TargetProperty="X" To="0" Duration="0:0:0.2"/>
                                        <ColorAnimation Storyboard.TargetName="SwitchTrack" Storyboard.TargetProperty="Background.Color" To="#E5E5E7" Duration="0:0:0.2"/>
                                    </Storyboard>
                                </BeginStoryboard>
                            </Trigger.ExitActions>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
</ResourceDictionary>
'@

$scrollViewerStyle = @'
<Style xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       TargetType="{x:Type ScrollViewer}">
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="{x:Type ScrollViewer}">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <ScrollContentPresenter Grid.Column="0" Margin="0,0,15,0"/>
                    <ScrollBar Grid.Column="1"
                               Name="PART_VerticalScrollBar"
                               Value="{TemplateBinding VerticalOffset}"
                               Maximum="{TemplateBinding ScrollableHeight}"
                               ViewportSize="{TemplateBinding ViewportHeight}"
                               Visibility="{TemplateBinding ComputedVerticalScrollBarVisibility}"
                               Width="12"
                               Margin="3,0,8,0">
                        <ScrollBar.Style>
                            <Style TargetType="ScrollBar">
                                <Setter Property="Background" Value="#2B2B2B"/>
                                <Setter Property="Template">
                                    <Setter.Value>
                                        <ControlTemplate TargetType="ScrollBar">
                                            <Grid>
                                                <Border Background="{TemplateBinding Background}" CornerRadius="6"/>
                                                <Track Name="PART_Track" IsDirectionReversed="True">
                                                    <Track.Thumb>
                                                        <Thumb>
                                                            <Thumb.Style>
                                                                <Style TargetType="Thumb">
                                                                    <Setter Property="Background" Value="#5A5A5A"/>
                                                                    <Setter Property="Template">
                                                                        <Setter.Value>
                                                                            <ControlTemplate TargetType="Thumb">
                                                                                <Border Background="{TemplateBinding Background}"
                                                                                        CornerRadius="6"
                                                                                        Margin="2"/>
                                                                            </ControlTemplate>
                                                                        </Setter.Value>
                                                                    </Setter>
                                                                    <Style.Triggers>
                                                                        <Trigger Property="IsMouseOver" Value="True">
                                                                            <Setter Property="Background" Value="#7A7A7A"/>
                                                                        </Trigger>
                                                                    </Style.Triggers>
                                                                </Style>
                                                            </Thumb.Style>
                                                        </Thumb>
                                                    </Track.Thumb>
                                                </Track>
                                            </Grid>
                                        </ControlTemplate>
                                    </Setter.Value>
                                </Setter>
                            </Style>
                        </ScrollBar.Style>
                    </ScrollBar>
                </Grid>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
'@

$window = New-Object System.Windows.Window
$window.Title = T 'WindowTitle'
$window.Width = 600
$window.Height = 700
$window.WindowStartupLocation = 'CenterScreen'
$window.ResizeMode = 'NoResize'
$window.Background = [System.Windows.Media.Brushes]::Black
$window.Foreground = [System.Windows.Media.Brushes]::White

$mainGrid = New-Object System.Windows.Controls.Grid
$window.Content = $mainGrid

$titleRow = New-Object System.Windows.Controls.RowDefinition
$titleRow.Height = New-Object System.Windows.GridLength(70)
$mainGrid.RowDefinitions.Add($titleRow) | Out-Null

$contentRow = New-Object System.Windows.Controls.RowDefinition
$contentRow.Height = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
$mainGrid.RowDefinitions.Add($contentRow) | Out-Null

$toggleRow = New-Object System.Windows.Controls.RowDefinition
$toggleRow.Height = New-Object System.Windows.GridLength(165)
$mainGrid.RowDefinitions.Add($toggleRow) | Out-Null

$bottomRow = New-Object System.Windows.Controls.RowDefinition
$bottomRow.Height = New-Object System.Windows.GridLength(80)
$mainGrid.RowDefinitions.Add($bottomRow) | Out-Null

$titlePanel = New-Object System.Windows.Controls.StackPanel
$titlePanel.Orientation = 'Vertical'
$titlePanel.HorizontalAlignment = 'Left'
$titlePanel.VerticalAlignment = 'Center'
$titlePanel.Margin = '20,0,0,0'
[System.Windows.Controls.Grid]::SetRow($titlePanel, 0)

$title = New-Object System.Windows.Controls.TextBlock
$title.Text = T 'Title'
$title.FontSize = 18
$title.FontWeight = 'Bold'
$title.Foreground = [System.Windows.Media.Brushes]::Cyan
Register-UiText -Control $title -Key 'Title'
$titlePanel.Children.Add($title) | Out-Null

$byline = New-Object System.Windows.Controls.TextBlock
$byline.Text = T 'ForkBy'
$byline.FontSize = 11
$byline.Foreground = [System.Windows.Media.Brushes]::Gray
Register-UiText -Control $byline -Key 'ForkBy'
$titlePanel.Children.Add($byline) | Out-Null

$mainGrid.Children.Add($titlePanel) | Out-Null

$langPanel = New-Object System.Windows.Controls.StackPanel
$langPanel.Orientation = 'Horizontal'
$langPanel.HorizontalAlignment = 'Right'
$langPanel.VerticalAlignment = 'Center'
$langPanel.Margin = '0,0,20,0'
[System.Windows.Controls.Grid]::SetRow($langPanel, 0)

$langLabel = New-Object System.Windows.Controls.TextBlock
$langLabel.Text = T 'LanguageLabel'
$langLabel.FontSize = 13
$langLabel.Foreground = [System.Windows.Media.Brushes]::Gray
$langLabel.VerticalAlignment = 'Center'
$langLabel.Margin = '0,0,8,0'
Register-UiText -Control $langLabel -Key 'LanguageLabel'
$langPanel.Children.Add($langLabel) | Out-Null

$langCombo = New-Object System.Windows.Controls.ComboBox
$langCombo.Width = 110
$langCombo.Height = 26
$langCombo.FontSize = 12
$langCombo.VerticalContentAlignment = 'Center'
$enItem = New-Object System.Windows.Controls.ComboBoxItem
$enItem.Content = 'English'
$zhItem = New-Object System.Windows.Controls.ComboBoxItem
$zhItem.Content = '简体中文'
[void]$langCombo.Items.Add($enItem)
[void]$langCombo.Items.Add($zhItem)
$langPanel.Children.Add($langCombo) | Out-Null
$mainGrid.Children.Add($langPanel) | Out-Null

$scrollViewer = New-Object System.Windows.Controls.ScrollViewer
$scrollViewer.VerticalScrollBarVisibility = 'Auto'
$scrollViewer.Margin = '20,5,20,10'
[System.Windows.Controls.Grid]::SetRow($scrollViewer, 1)
$scrollViewer.Style = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader([xml]$scrollViewerStyle)))
$mainGrid.Children.Add($scrollViewer) | Out-Null

$stackPanel = New-Object System.Windows.Controls.StackPanel
$stackPanel.Orientation = 'Vertical'
$scrollViewer.Content = $stackPanel

function New-SectionHeader {
    param([string]$Key, [double]$FontSize)
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Text = T $Key
    $header.FontSize = $FontSize
    $header.FontWeight = 'Bold'
    $header.Foreground = [System.Windows.Media.Brushes]::Cyan
    $header.Margin = '0,10,0,10'
    Register-UiText -Control $header -Key $Key
    return $header
}

function New-InfoButton {
    param([string]$Func)
    $infoButton = New-Object System.Windows.Controls.Button
    $infoButton.Content = '?'
    $infoButton.Width = 25
    $infoButton.Height = 25
    $infoButton.FontSize = 12
    $infoButton.FontWeight = 'Bold'
    $infoButton.Background = [System.Windows.Media.Brushes]::DarkBlue
    $infoButton.Foreground = [System.Windows.Media.Brushes]::White
    $infoButton.BorderBrush = [System.Windows.Media.Brushes]::Transparent
    $infoButton.BorderThickness = 0
    $infoButton.VerticalAlignment = 'Center'
    $infoButton.Cursor = 'Hand'
    $infoButton.Tag = $Func
    $infoButton.Template = [System.Windows.Markup.XamlReader]::Parse($roundButtonTemplate -replace '__CORNER__', '12')
    Register-UiText -Control $infoButton -Key 'InfoAria' -Property 'Aria' -Func $Func
    Register-UiText -Control $infoButton -Key 'InfoAriaHelp' -Property 'Help'
    $infoButton.Add_Click({
            param($sender, $e)
            $funcName = $sender.Tag
            [System.Windows.MessageBox]::Show((T "desc_$funcName"), (T "opt_$funcName"), [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        })
    return $infoButton
}

function Add-OptionRow {
    param([System.Windows.Controls.Panel]$Parent, [hashtable]$Option)
    $func = $Option.Func

    $optionContainer = New-Object System.Windows.Controls.DockPanel
    $optionContainer.Margin = '0,5,0,5'
    $optionContainer.LastChildFill = $false

    $infoButton = New-InfoButton -Func $func
    [System.Windows.Controls.DockPanel]::SetDock($infoButton, 'Right')

    $checkboxPanel = New-Object System.Windows.Controls.StackPanel
    $checkboxPanel.Orientation = 'Horizontal'
    $checkboxPanel.VerticalAlignment = 'Center'

    $checkboxLabel = New-Object System.Windows.Controls.TextBlock
    $checkboxLabel.Text = T "opt_$func"
    $checkboxLabel.FontSize = 14
    $checkboxLabel.Foreground = [System.Windows.Media.Brushes]::White
    $checkboxLabel.VerticalAlignment = 'Center'
    $script:optionLabels[$func] = $checkboxLabel
    $checkboxPanel.Children.Add($checkboxLabel) | Out-Null

    if ($Option.Warning) {
        $warningIcon = New-Object System.Windows.Controls.TextBlock
        $warningIcon.Text = ' ⚠'
        $warningIcon.FontSize = 14
        $warningIcon.Foreground = New-Object System.Windows.Media.SolidColorBrush(([System.Windows.Media.Color]::FromRgb(255, 180, 0)))
        $warningIcon.VerticalAlignment = 'Center'
        $warningIcon.Cursor = 'Arrow'

        $tooltip = New-Object System.Windows.Controls.ToolTip
        $tooltip.Content = T 'WarningTooltip'
        $tooltip.Background = New-Object System.Windows.Media.SolidColorBrush(([System.Windows.Media.Color]::FromRgb(60, 30, 0)))
        $tooltip.Foreground = [System.Windows.Media.Brushes]::Yellow
        $tooltip.FontSize = 11
        $tooltip.BorderBrush = New-Object System.Windows.Media.SolidColorBrush(([System.Windows.Media.Color]::FromRgb(180, 100, 0)))
        $tooltip.BorderThickness = 1
        $tooltip.Padding = '6,4,6,4'
        $warningIcon.ToolTip = $tooltip
        Register-UiText -Control $warningIcon -Key 'WarningTooltip' -Property 'ToolTip'

        $checkboxPanel.Children.Add($warningIcon) | Out-Null
    }

    $checkbox = New-Object System.Windows.Controls.CheckBox
    $checkbox.Content = $checkboxPanel
    $checkbox.FontSize = 14
    $checkbox.Foreground = [System.Windows.Media.Brushes]::White
    $checkbox.Margin = '0,0,10,0'
    $checkbox.VerticalAlignment = 'Center'
    $checkbox.IsChecked = $Option.Checked
    $checkbox.Tag = $func
    [System.Windows.Controls.DockPanel]::SetDock($checkbox, 'Left')
    $script:checkboxes[$func] = $checkbox

    $optionContainer.Children.Add($infoButton) | Out-Null
    $optionContainer.Children.Add($checkbox) | Out-Null
    $Parent.Children.Add($optionContainer) | Out-Null
}

[void]$stackPanel.Children.Add((New-SectionHeader -Key 'SectionRemoval' -FontSize 14))
foreach ($opt in $script:removalFunctions) {
    Add-OptionRow -Parent $stackPanel -Option $opt
}

$divider = New-Object System.Windows.Controls.Separator
$divider.Margin = '0,10,0,10'
$divider.Background = [System.Windows.Media.Brushes]::DarkGray
$stackPanel.Children.Add($divider) | Out-Null

[void]$stackPanel.Children.Add((New-SectionHeader -Key 'SectionClassic' -FontSize 16))
foreach ($opt in $script:classicFunctions) {
    Add-OptionRow -Parent $stackPanel -Option $opt
}

$toggleGrid = New-Object System.Windows.Controls.Grid
[System.Windows.Controls.Grid]::SetRow($toggleGrid, 2)
$toggleGrid.Margin = '20,10,55,15'

$toggleRow1 = New-Object System.Windows.Controls.RowDefinition
$toggleRow1.Height = [System.Windows.GridLength]::Auto
$toggleRow2 = New-Object System.Windows.Controls.RowDefinition
$toggleRow2.Height = [System.Windows.GridLength]::Auto
$toggleRow3 = New-Object System.Windows.Controls.RowDefinition
$toggleRow3.Height = [System.Windows.GridLength]::Auto
$toggleGrid.RowDefinitions.Add($toggleRow1) | Out-Null
$toggleGrid.RowDefinitions.Add($toggleRow2) | Out-Null
$toggleGrid.RowDefinitions.Add($toggleRow3) | Out-Null
$mainGrid.Children.Add($toggleGrid) | Out-Null

$toggleResourceDict = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader([xml]$toggleStyleXaml)))

function Add-ModeToggle {
    param([System.Windows.Controls.Grid]$ParentGrid, [int]$Row, [string]$LabelKey, [string]$TitleKey, [string]$InfoKey, [bool]$IsChecked)
    $panel = New-Object System.Windows.Controls.DockPanel
    $panel.HorizontalAlignment = 'Left'
    $panel.VerticalAlignment = 'Center'
    $panel.Margin = New-Object System.Windows.Thickness(0, 0, 0, 10)
    $panel.LastChildFill = $false
    [System.Windows.Controls.Grid]::SetRow($panel, $Row)

    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = T $LabelKey
    $label.Foreground = [System.Windows.Media.Brushes]::White
    $label.VerticalAlignment = 'Center'
    $label.Margin = New-Object System.Windows.Thickness(0, 0, 10, 0)
    Register-UiText -Control $label -Key $LabelKey
    [System.Windows.Controls.DockPanel]::SetDock($label, 'Left')
    $panel.Children.Add($label) | Out-Null

    $toggle = New-Object System.Windows.Controls.Primitives.ToggleButton
    $toggle.IsChecked = $IsChecked
    $toggle.Style = $toggleResourceDict['CleanToggleStyle']
    [System.Windows.Automation.AutomationProperties]::SetName($toggle, (T $TitleKey))
    [System.Windows.Controls.DockPanel]::SetDock($toggle, 'Left')
    $panel.Children.Add($toggle) | Out-Null

    $infoButton = New-InfoButton -Func $null
    $infoButton.Margin = New-Object System.Windows.Thickness(10, 0, 0, 0)
    $infoButton.Tag = "$TitleKey|$InfoKey"
    [System.Windows.Controls.DockPanel]::SetDock($infoButton, 'Right')
    $infoButton.Add_Click({
            param($sender, $e)
            $parts = $sender.Tag -split '\|'
            [System.Windows.MessageBox]::Show((T $parts[1]), (T $parts[0]), [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        })
    Register-UiText -Control $infoButton -Key 'InfoAria' -Property 'Aria' -Func $TitleKey
    Register-UiText -Control $infoButton -Key 'InfoAriaHelp' -Property 'Help'
    $panel.Children.Add($infoButton) | Out-Null

    $ParentGrid.Children.Add($panel) | Out-Null
    return $toggle
}

$script:revertModeToggle = Add-ModeToggle -ParentGrid $toggleGrid -Row 0 -LabelKey 'RevertMode' -TitleKey 'RevertModeTitle' -InfoKey 'RevertInfo' -IsChecked $false
$script:backupModeToggle = Add-ModeToggle -ParentGrid $toggleGrid -Row 1 -LabelKey 'BackupMode' -TitleKey 'BackupModeTitle' -InfoKey 'BackupInfo' -IsChecked $false

$shortcutPanel = New-Object System.Windows.Controls.DockPanel
$shortcutPanel.HorizontalAlignment = 'Left'
$shortcutPanel.VerticalAlignment = 'Center'
$shortcutPanel.Margin = New-Object System.Windows.Thickness(0, 10, 0, 0)
$shortcutPanel.LastChildFill = $false
[System.Windows.Controls.Grid]::SetRow($shortcutPanel, 2)

$desktopShortcutCheckbox = New-Object System.Windows.Controls.CheckBox
$desktopShortcutCheckbox.Content = T 'DesktopShortcut'
$desktopShortcutCheckbox.FontSize = 14
$desktopShortcutCheckbox.Foreground = [System.Windows.Media.Brushes]::White
$desktopShortcutCheckbox.Margin = New-Object System.Windows.Thickness(0, 0, 20, 0)
$desktopShortcutCheckbox.VerticalAlignment = 'Center'
$desktopShortcutCheckbox.IsChecked = $false
Register-UiText -Control $desktopShortcutCheckbox -Key 'DesktopShortcut'
[System.Windows.Controls.DockPanel]::SetDock($desktopShortcutCheckbox, 'Left')
$shortcutPanel.Children.Add($desktopShortcutCheckbox) | Out-Null

$startMenuShortcutCheckbox = New-Object System.Windows.Controls.CheckBox
$startMenuShortcutCheckbox.Content = T 'StartMenuShortcut'
$startMenuShortcutCheckbox.FontSize = 14
$startMenuShortcutCheckbox.Foreground = [System.Windows.Media.Brushes]::White
$startMenuShortcutCheckbox.Margin = New-Object System.Windows.Thickness(0, 0, 10, 0)
$startMenuShortcutCheckbox.VerticalAlignment = 'Center'
$startMenuShortcutCheckbox.IsChecked = $false
Register-UiText -Control $startMenuShortcutCheckbox -Key 'StartMenuShortcut'
[System.Windows.Controls.DockPanel]::SetDock($startMenuShortcutCheckbox, 'Left')
$shortcutPanel.Children.Add($startMenuShortcutCheckbox) | Out-Null

$shortcutInfoButton = New-InfoButton -Func $null
$shortcutInfoButton.Tag = 'ShortcutTitle|ShortcutInfo'
$shortcutInfoButton.Add_Click({
        param($sender, $e)
        $parts = $sender.Tag -split '\|'
        [System.Windows.MessageBox]::Show((T $parts[1]), (T $parts[0]), [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
[System.Windows.Controls.DockPanel]::SetDock($shortcutInfoButton, 'Right')
$shortcutPanel.Children.Add($shortcutInfoButton) | Out-Null
$toggleGrid.Children.Add($shortcutPanel) | Out-Null

$script:revertModeToggle.Add_Checked({
        $script:backupModeToggle.IsChecked = $false
        $Global:revert = 1
    }) | Out-Null
$script:revertModeToggle.Add_Unchecked({
        $Global:revert = 0
    }) | Out-Null
$script:backupModeToggle.Add_Checked({
        $script:revertModeToggle.IsChecked = $false
        $Global:backup = 1
    }) | Out-Null
$script:backupModeToggle.Add_Unchecked({
        $Global:backup = 0
    }) | Out-Null

$bottomGrid = New-Object System.Windows.Controls.Grid
[System.Windows.Controls.Grid]::SetRow($bottomGrid, 3)
$bottomGrid.Margin = '25,15,25,15'

$leftColumn = New-Object System.Windows.Controls.ColumnDefinition
$leftColumn.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
$bottomGrid.ColumnDefinitions.Add($leftColumn) | Out-Null

$rightColumn = New-Object System.Windows.Controls.ColumnDefinition
$rightColumn.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
$bottomGrid.ColumnDefinitions.Add($rightColumn) | Out-Null

$socialPanel = New-Object System.Windows.Controls.StackPanel
$socialPanel.Orientation = 'Horizontal'
$socialPanel.HorizontalAlignment = 'Left'
$socialPanel.VerticalAlignment = 'Center'
[System.Windows.Controls.Grid]::SetColumn($socialPanel, 0)

$githubButton = New-RoundButton -Width 85 -Height 30 -CornerRadius 15 -BackgroundHex '#535353' -Content 'GitHub'
$githubButton.ToolTip = T 'GitHubTooltip'
Register-UiText -Control $githubButton -Key 'GitHubTooltip' -Property 'ToolTip'
$githubButton.Add_Click({
        Start-Process 'https://github.com/Zombie-Kaiser/RemoveWindowsAI'
    })
$socialPanel.Children.Add($githubButton) | Out-Null

$discordButton = New-RoundButton -Width 85 -Height 30 -CornerRadius 15 -BackgroundHex '#7289DA' -Content 'Discord'
$discordButton.ToolTip = T 'DiscordTooltip'
Register-UiText -Control $discordButton -Key 'DiscordTooltip' -Property 'ToolTip'
$discordButton.Margin = '10,0,0,0'
$discordButton.Add_Click({
        Start-Process 'https://discord.gg/VsC7XS5vgA'
    })
$socialPanel.Children.Add($discordButton) | Out-Null

$actionPanel = New-Object System.Windows.Controls.StackPanel
$actionPanel.Orientation = 'Horizontal'
$actionPanel.HorizontalAlignment = 'Right'
$actionPanel.VerticalAlignment = 'Center'
[System.Windows.Controls.Grid]::SetColumn($actionPanel, 1)

$cancelButton = New-RoundButton -Width 80 -Height 35 -CornerRadius 17 -BackgroundHex '#8B0000' -Content (T 'Cancel')
Register-UiText -Control $cancelButton -Key 'Cancel'
$cancelButton.Margin = '0,0,10,0'
$cancelButton.Add_Click({
        $window.Close()
    })
$actionPanel.Children.Add($cancelButton) | Out-Null

$applyButton = New-RoundButton -Width 80 -Height 35 -CornerRadius 17 -BackgroundHex '#006400' -Content (T 'Apply')
Register-UiText -Control $applyButton -Key 'Apply'
$applyButton.Add_Click({
        try {
            $tempRoot = [System.IO.Path]::GetTempPath()
            Remove-Item (Join-Path $tempRoot 'Microsoft.PhotosLegacy_8wekyb3d8bbwe') -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item (Join-Path $tempRoot 'ZoicwareRemoveWindowsAI-*.cab') -Force -ErrorAction SilentlyContinue

            $aiProcesses = @(
                'ai.exe'
                'Copilot.exe'
                'aihost.exe'
                'aicontext.exe'
                'ClickToDo.exe'
                'aixhost.exe'
                'WorkloadsSessionHost.exe'
                'WebViewHost.exe'
                'aimgr.exe'
                'AppActions.exe'
                'M365Copilot.exe'
                'm365copilot_autostarter.exe'
            )
            foreach ($procName in $aiProcesses) {
                taskkill /im $procName /f *>$null
            }

            $progressWindow = New-Object System.Windows.Window
            $progressWindow.Title = T 'ProgressTitle'
            $progressWindow.Width = 400
            $progressWindow.Height = 200
            $progressWindow.WindowStartupLocation = 'CenterOwner'
            $progressWindow.Owner = $window
            $progressWindow.Background = [System.Windows.Media.Brushes]::Black
            $progressWindow.Foreground = [System.Windows.Media.Brushes]::White
            $progressWindow.ResizeMode = 'NoResize'

            $progressGrid = New-Object System.Windows.Controls.Grid
            $progressWindow.Content = $progressGrid

            $progressText = New-Object System.Windows.Controls.TextBlock
            $progressText.Text = T 'ProgressInit'
            $progressText.FontSize = 14
            $progressText.Foreground = [System.Windows.Media.Brushes]::Cyan
            $progressText.HorizontalAlignment = 'Center'
            $progressText.VerticalAlignment = 'Center'
            $progressText.TextWrapping = 'Wrap'
            $progressGrid.Children.Add($progressText) | Out-Null

            $progressWindow.Show()

            $selectedFunctions = @()
            foreach ($func in $script:allFunctions) {
                if ($script:checkboxes[$func].IsChecked) {
                    $selectedFunctions += $func
                }
            }

            if ($selectedFunctions.Count -eq 0 -and !$desktopShortcutCheckbox.IsChecked -and !$startMenuShortcutCheckbox.IsChecked) {
                $progressWindow.Close()
                [System.Windows.MessageBox]::Show((T 'NoOptions'), (T 'NoOptionsTitle'), [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                return
            }

            try {
                if ($Global:backup) {
                    $progressText.Text = T 'ProgressInit'
                    $progressWindow.UpdateLayout()
                    [System.Windows.Forms.Application]::DoEvents()
                    Create-RestorePoint
                }
                foreach ($func in $selectedFunctions) {
                    $progressText.Text = (T 'ProgressExecuting') -f (T "opt_$func")
                    $progressWindow.UpdateLayout()
                    [System.Windows.Forms.Application]::DoEvents()

                    switch ($func) {
                        'Disable-Registry-Keys'          { Disable-Registry-Keys }
                        'Prevent-AI-Package-Reinstall'   { Install-NOAIPackage }
                        'Disable-Copilot-Policies'       { Disable-Copilot-Policies }
                        'Remove-AI-Appx-Packages'        { Remove-AI-Appx-Packages }
                        'Remove-Recall-Optional-Feature' { Remove-Recall-Optional-Feature }
                        'Remove-AI-CBS-Packages'         { Remove-AI-CBS-Packages }
                        'Remove-AI-Files'                { Remove-AI-Files }
                        'Hide-AI-Components'             { Hide-AI-Components }
                        'Disable-Notepad-Rewrite'        { Disable-Notepad-Rewrite }
                        'Remove-WindowsAI-Tasks'         { Remove-WindowsAI-Tasks }
                        'Update-Cleanup-Check'           { Update-Cleanup-Check }
                        'Disable-DefenderAI'             { Disable-DefenderAI }
                        'Install-Classic-Photoviewer'    { install-classicapps -app 'photoviewer' }
                        'Install-Classic-Mspaint'        { install-classicapps -app 'mspaint' }
                        'Install-Classic-SnippingTool'   { install-classicapps -app 'snippingtool' }
                        'Install-Classic-Notepad'        { install-classicapps -app 'notepad' }
                        'Install-Photos-Legacy'          { install-classicapps -app 'photoslegacy' }
                    }

                    Start-Sleep -Milliseconds 500
                }

                if ($desktopShortcutCheckbox.IsChecked -or $startMenuShortcutCheckbox.IsChecked) {
                    $progressText.Text = T 'ProgressShortcuts'
                    $progressWindow.UpdateLayout()
                    [System.Windows.Forms.Application]::DoEvents()
                    Create-ScriptShortcut -Desktop:$desktopShortcutCheckbox.IsChecked -Start:$startMenuShortcutCheckbox.IsChecked
                }

                $progressText.Text = T 'ProgressDone'
                Start-Sleep -Seconds 2
                $progressWindow.Close()

                $result = [System.Windows.MessageBox]::Show((T 'DoneMsg'), (T 'DoneTitle'), [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)

                if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                    try { Remove-Item "$($tempRoot)aiPackageRemoval.ps1" -Force -ErrorAction SilentlyContinue } catch {}
                    try { Remove-Item "$($tempRoot)RemoveRecallTasks.ps1" -Force -ErrorAction SilentlyContinue } catch {}
                    try { Remove-Item "$($tempRoot)PathsToDelete.txt" -Force -ErrorAction SilentlyContinue } catch {}
                    try { Remove-Item "$($tempRoot)ZoicwareRemoveWindowsAI-*1.0.0.0.cab" -Force -ErrorAction SilentlyContinue } catch {}
                    try { Remove-Item "$($tempRoot)ZoicwareRemoveWindowsAI-*1.0.0.1.cab" -Force -ErrorAction SilentlyContinue } catch {}
                    Restart-Computer -Force
                }

                $window.Close()
            }
            catch {
                $progressWindow.Close()
                [System.Windows.MessageBox]::Show(((T 'ErrorOccurred') -f $_.Exception.Message), (T 'ErrorTitle'), [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
        }
        catch {
            [System.Windows.MessageBox]::Show(((T 'ErrorOccurred') -f $_.Exception.Message), (T 'ErrorTitle'), [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })
$actionPanel.Children.Add($applyButton) | Out-Null

$bottomGrid.Children.Add($socialPanel) | Out-Null
$bottomGrid.Children.Add($actionPanel) | Out-Null
$mainGrid.Children.Add($bottomGrid) | Out-Null

$langCombo.SelectedIndex = if ($script:lang -eq 'zh') { 1 } else { 0 }
$langCombo.Add_SelectionChanged({
        param($sender, $e)
        $newLang = if ($langCombo.SelectedIndex -eq 1) { 'zh' } else { 'en' }
        if ($newLang -ne $script:lang) {
            $script:lang = $newLang
            Save-Language -lang $newLang
            Update-UiLanguage
        }
    })

$window.ShowDialog() | Out-Null
