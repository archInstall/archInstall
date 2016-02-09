#!/bin/bash --login

# region header

# Copyright Torben Sickert 16.12.2012

# License
#    This library written by Torben Sickert stand under a creative commons
#    naming 3.0 unported license.
#    see http://creativecommons.org/licenses/by/3.0/deed.de

# endregion

# Prints a dummy documentation content.
function printDummyDocumentationContent() {
    cat << EOF
h2(id="content")
    | Content
    //deDE:Inhalt
//|frFR:franz
//|deDE:deutsch
h3(id="a") english
div.toc: ul
    li: a(href="#") english
    li: a(href="#") english
    li: a(href="#content")
        | Content
        //deDE:Inhalt
    li
        //|deDE:JAU
        a(href="#content") Vor
    li: a(href="#getting-in")
        | Getting in
        //deDE:Einstieg
        ul
            li: a(href="#a") a
            li: a(href="#b") b
    li: a(href="#c") c
    ul: li
        a(href="#d") d
        ul: li: a(href="#e") e
h2(id="getting-in")
    langreplace
        | Getting
        code inline
        | in
    //deDE:Einstieg<code>inline code</code>
p Englisch//deDE:Deutsch ipsum dolor sit amet...
h3(id="a") a
p
    | Lorem ipsum dolor sit amet
    code mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
h3(id="b") b
p Lorem ipsum dolor sit amet...
h2(id="c") c
p Lorem ipsum dolor sit amet...
h3(id="d") d
p Lorem ipsum dolor sit amet...
div.codehilite
    pre &gt;&gt;&gt; /path/to/boostNode/runnable/macro.py -p /path/to/boostNode -e py
div.codehilite
    pre &gt;&gt;&gt; /path/to/boostNode/runnable/macro.py -p /path/to/boostNode -e py --looooooooong options -shorter
//showExample
table.codehilitetable: tr
    td.linenos: div.linenodiv: pre.
        1
        2
        3
    td.code: div.codehilite: pre.
        <span class="nt">&lt;form</span> <span class="na">method=</span><span class="s">&quot;get&quot;</span> <span class="na">action=</span><span class="s">&quot;#&quot;</span><span class="nt">&gt;</span>
            <span class="nt">&lt;input</span> <span class="na">class=</span><span class="s">&quot;form-control&quot;</span> <span class="na">type=</span><span class="s">&quot;text&quot;</span> <span class="na">name=</span><span class="s">&quot;test&quot;</span> <span class="na">value=</span><span class="s">&quot;4&quot;</span><span class="nt">/&gt;</span>
        <span class="nt">&lt;/form&gt;</span>
p.
    Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet.Lorem ipsum dolor
    sit amet. Lorem ipsum dolor sit amet. sit amet. Lorem ipsum dolor sit
    amet. sit amet. Lorem ipsum dolor sit amet. sit amet. Lorem ipsum dolor
    sit amet. sit amet. Lorem ipsum dolor sit amet...
//showExample
div.codehilite: pre &lt;p&gt;test text&lt;/p&gt;
p Lorem ipsum dolor sit amet...
//showExample:js
div.codehilite: pre window.test = 5 * 2;
p Lorem ipsum dolor sit amet...
//showExample:css
div.codehilite: pre border: 0px solid black;
p Lorem ipsum dolor sit amet...
table.codehilitetable: tbody: tr
    td.linenos: div.linenodiv: pre.
        10
        11
        12
        100
        111
        999
    td.code: div.codehilite: pre.
        <span class="err">#</span><span class="o">!</span><span class="err">/usr/bin/env javaScript</span>
        <span class="kd">var</span> <span class="nx">tools</span> <span class="o">=</span><span class="nx">jQuery</span><span class="p">.</span><span class="nx">Tools</span><span class="p">({</span><span class="s1">&#39; logging&#39;</span><span class="o">:</span><span class="kc">true</span><span class="p">});</span>
        <span class="kd">var</span> <span class="nx">tools</span> <span class="o">=</span><span class="nx">jQuery</span><span class="p">.</span><span class="nx">Tools</span><span class="p">({</span><span class="s1">&#39;logging&#39;</span><span class="o">:</span><span class="kc">true</span><span class="p">});</span>
        <span class="c1">// An 79 chars comment: mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm</span>
        <span class="nx">tools</span><span class="p">.</span><span class="nx">log</span><span class="p">(</span><span class="s1">&#39;test&#39;</span><span class="p">);</span>
        <span class="nx">tools</span><span class="p">.</span><span class="nx">log</span><span class="p">(</span><span class="s1">&#39;test&#39;</span><span class="p">);</span>
h3(id="e") e
table.codehilitetable: tr
    td.linenos: div.linenodiv: pre.
        1
        2
        3
        4
        5
        6
        7
        8
        9
        10
        11
        12
        13
        14
        15
        16
        17
        18
    td.code: div.codehilite: pre.
        <span class="c">#!/usr/bin/env bash</span>

        cat span.s &lt;&lt; EOF
            <span class="s">Usage: $0 &lt;initramfsFilePath&gt; [options]</span>

            <span class="s">\$__NAME__ installs an arch linux into an initramfs file.</span>

            <span class="s">Option descriptions:</span>

            <span class="s">\$(installArchLinuxPrintCommandLineOptionDescriptions &quot;\$@&quot; | \</span>
            <span class="s">    sed &#39;/^ *-[a-z] --output-system .*$/,/^$/d&#39;)</span>
        <span class="s">EOF</span>

        <span class="nv">myTarget</span><span class="o">=</span><span class="k">\$(</span>mktemp<span class="k">)</span>

        installArchLinux <span class="s2">&quot;\$@&quot;</span> --output-system <span class="nv">\$myTarget</span>

        <span class="c"># test...</span>
p Lorem ipsum dolor sit amet...
EOF
    }

for render_file_path in index.jade.tpl coffeeScript/main.coffee.tpl; do
    template "$render_file_path" --pretty-indent --scope-variables \
        CONTENT_IN_JADE='true' TAGLINE='tagline' NAME='productName' \
        LANGUAGE='en' LANGUAGES='' GOOGLE_TRACKING_CODE='__none__' \
        URL='https://github.com/thaibault/documentationWebsite' \
        SOURCE_URL='https://github.com/thaibault/documentationWebsite' \
        CONTENT="$(printDummyDocumentationContent)" \
    1>"$(sed --regexp-extended 's/^(.+)\.[^\.]+$/\1/g' <<< "$render_file_path")"
done

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
