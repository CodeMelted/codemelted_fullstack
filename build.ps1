#!/usr/local/bin/pwsh
# =============================================================================
# MIT License
#
# © 2023 Mark Shaffer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
# =============================================================================
function build([string[]]$params) {
    # -------------------------------------------------------------------------
    # Constants
    # -------------------------------------------------------------------------
    [string]$PROJ_NAME = "CodeMelted Fullstack Module"
    [string]$GEN_HTML_PERL_SCRIPT = "/ProgramData/chocolatey/lib/lcov/tools/bin/genhtml"

    # -------------------------------------------------------------------------
    # Helper Function
    # -------------------------------------------------------------------------
    function message([string]$msg) {
        Write-Host
        Write-Host "MESSAGE: $msg"
        Write-Host
    }

    # -------------------------------------------------------------------------
    # Main Build Script
    # -------------------------------------------------------------------------
    message "Now building $PROJ_NAME"

    message "Setting up the dist directory"

    Remove-Item -Path "docs" -Force -Recurse -ErrorAction Ignore

    message "Now Running Deno tests"
    deno test --allow-env --allow-net --allow-read --allow-sys --allow-write --coverage=coverage codemelted_fullstack_test.js
    deno coverage coverage --lcov > coverage/lcov.info

    if ($IsLinux -or $IsMacOS) {
        genhtml -o coverage --ignore-errors unused --dark-mode coverage/lcov.info
    } else {
        $exists = Test-Path -Path $GEN_HTML_PERL_SCRIPT -PathType Leaf
        if ($exists) {
            perl $GEN_HTML_PERL_SCRIPT -o coverage coverage/lcov.info
        } else {
            Write-Host "WARNING: genhtml not installed for windows. Run " +
                "'choco install lcov' for pwsh terminal as Admin to install it."
        }
    }

    message "Now generating the jsdoc"
    if ($IsWindows) {
        jsdoc --configure theme/jsdoc-win.json --verbose
    } else {
        jsdoc --configure theme/jsdoc-linux-mac.json --verbose
    }
    Move-Item -Path coverage -Destination docs -Force

    # Fix the title
    [string]$htmlData = Get-Content -Path "docs/index.html"
    $htmlData = $htmlData.Replace("<title>Home</title>", "<title>CodeMelted - Fullstack Module</title>")
    $htmlData | Out-File docs/index.html -Force

    message "$PROJ_NAME build completed"
}
build $args