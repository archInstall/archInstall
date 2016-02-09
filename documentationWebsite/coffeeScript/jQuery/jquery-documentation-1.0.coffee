#!/usr/bin/env coffee
# -*- coding: utf-8 -*-

# region header

###
This plugin provides generic documentation page features.

Copyright Torben Sickert 16.12.2012

License
-------

This library written by Torben Sickert stand under a creative commons naming
3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de

Extending this module
---------------------

For conventions see require on https://github.com/thaibault/require

Author
------

t.sickert["~at~"]gmail.com (Torben Sickert)

Version
-------

1.0 stable
###

main = ($) ->

# endregion

# region plugins

    class Documentation extends $.Website.class
        ###
            This plugin holds all needed methods to extend a whole
            documentation site.
        ###

    # region properties

        ###
            **__name__ {String}**
            Holds the class name to provide inspection features.
        ###
        __name__: 'Documentation'

    # endregion

    # region public methods

        # region special

        ###
            Initializes the interactive web application.

            **options {Object}**          - An options object.

            **returns {$.Documentation}** - Returns the current instance.
        ###
        initialize: (
            options={}, @startUpAnimationIsComplete=false,
            @_activateLanguageSupport=false, @_languageHandler=null
        ) ->
            this._options =
                onExamplesLoaded: $.noop()
                domNodeSelectorPrefix: 'body.{1}'
                codeTableWrapper: '<div class="table-responsive">'
                showExample:
                    pattern: '^ *showExample(: *([^ ]+))? *$'
                    domNodeName: '#comment'
                    htmlWrapper: '''
                        <div class="show-example-wrapper">
                            <h3>
                                Example:
                                <!--deDE:Beispiel:-->
                                <!--frFR:Exemple:-->
                            </h3>
                        </div>
                    '''
                domNode:
                    tableOfContentLinks: 'div.toc > ul > li a[href^="#"]'
                    aboutThisWebsiteLink: 'a[href="#about-this-website"]'
                    homeLink: 'a[href="#home"]'
                    aboutThisWebsiteSection: 'section.about-this-website'
                    mainSection: 'section.main-content'
                    codeWrapper: 'div.codehilite'
                    code: 'div.codehilite > pre, code'
                section:
                    aboutThisWebsite:
                        fadeOut: duration: 'fast'
                        fadeIn: duration: 'fast'
                    main:
                        fadeOut: duration: 'fast'
                        fadeIn: duration: 'fast'
            # NOTE: We will initialize language support after examples are
            # injected if activated via options.
            this._activateLanguageSupport = options.activateLanguageSupport
            options.activateLanguageSupport = false
            super options
            if not this._activateLanguageSupport?
                this._activateLanguageSupport =
                    this._parentOptions.activateLanguageSupport
            if not window.location.hash
                window.location.hash = this.$domNodes.homeLink.attr 'href'
            this.$domNodes.aboutThisWebsiteSection.hide()
            # NOTE: We have to render examples first to avoid having dots in
            # example code.
            this._showExamples()._makeCodeEllipsis()
            this.on this.$domNodes.tableOfContentLinks, 'click', ->
                $.scrollTo $(this).attr('href'), 'slow'
            # Handle section switch between documentation and
            # "about this website".
            this._options.section.aboutThisWebsite.fadeOut.always = =>
                this.$domNodes.mainSection.fadeIn(
                    this._options.section.main.fadeIn)
            this._options.section.main.fadeOut.always = =>
                this.$domNodes.aboutThisWebsiteSection.fadeIn(
                    this._options.section.aboutThisWebsite.fadeIn)
            this.on this.$domNodes.aboutThisWebsiteLink, 'click', =>
                this._scrollToTop().$domNodes.mainSection.fadeOut(
                    this._options.section.main.fadeOut)
            this.on this.$domNodes.homeLink, 'click', (event) =>
                this._scrollToTop().$domNodes.aboutThisWebsiteSection.fadeOut(
                    this._options.section.aboutThisWebsite.fadeOut)
            this

        # endregion

         # region event handler

        _onExamplesLoaded: ->
            ###
                This method triggers if all examples loaded.

                **returns {$.Documentation}** - Returns the current instance.
            ###
            # NOTE: After injecting new dom nodes we have to grab them for
            # further controller logic.
            this.$domNodes = this.grabDomNode this._options.domNode
            # New injected dom nodes may take affect on language handler.
            if(this.startUpAnimationIsComplete and
               this._activateLanguageSupport and not this._languageHandler?)
                this._languageHandler = $.Lang this._options.language
            this
        _onSwitchSection: (sectionName) ->
            ###
                This method triggers if we change the current section.

                **returns {$.Documentation}** - Returns the current instance.
            ###
            this.$domNodes.tableOfContentLinks.add(
                this.$domNodes.aboutThisWebsiteLink
            ).add(this.$domNodes.homeLink).filter(
                "a[href=\"##{sectionName}\"]"
            ).trigger 'click'
            super
        _onStartUpAnimationComplete: ->
            ###
                This method triggers if all startup animations are ready.

                **returns {$.Documentation}** - Returns the current instance.
            ###
            if this._activateLanguageSupport and not this._languageHandler?
                this._languageHandler = $.Lang this._options.language
            # All start up effects are ready. Handle direct
            # section links.
            this.startUpAnimationIsComplete = true
            this.$domNodes.tableOfContentLinks.add(
                this.$domNodes.aboutThisWebsiteLink
            ).filter('a[href="' + window.location.href.substr(
                window.location.href.indexOf '#'
            ) + '"]').trigger 'click'
            super

        # endregion

    # endregion

    # region protected methods

        ###
            This method makes dotes after code lines which are too long. This
            prevents line wrapping.

            **returns {$.Documentation}** - Returns the current instance.
        ###
        _makeCodeEllipsis: ->
            this.$domNodes.code.each (index, domNode) =>
                $domNode = $ domNode
                tableParent = $domNode.closest 'table'
                if tableParent.length
                    tableParent.wrap this._options.codeTableWrapper
                newContent = ''
                codeLines = $domNode.html().split '\n'
                $.each codeLines, (index, value) =>
                    # NOTE: Wrap a div object to grantee that $ will accept the
                    # input.
                    excess = $("<div>#{value}</div>").text().length - 79
                    if excess > 0
                        newContent += this._replaceExcessWithDots value, excess
                    else
                        newContent += value
                    if index + 1 isnt codeLines.length
                        newContent += "\n"
                $domNode.html newContent
            this
        _replaceExcessWithDots: (content, excess) ->
            ###
                Replaces given html content with a shorter version trimmed by
                given amount of excess.

                **content {String}** - String to trim.
                **excess {Number}**  - Amount of excess.

                **returns {String}** - Returns the trimmed content.
            ###
            # Add space for ending dots.
            excess += 3
            newContent = ''
            try
                $content = $ content
                throw window.Error('error') if not $content.length
            catch error
                # NOTE: Wrap an element around to grantee that $ will accept
                # the input. We don't wrap an element in general to iterate
                # through separate dom nodes in next step if possible.
                $content = $ "<wrapper>#{content}</wrapper>"
                wrapped = true
            $($content.get().reverse()).each ->
                # Wrap element to get not only the inner html. Wrap only if not
                # wrapped already.
                if wrapped
                    $wrapper = $ this
                else
                    $wrapper = $(this).wrap('<wrapper>').parent()
                contentSnippet = $wrapper.html()
                if not contentSnippet
                    contentSnippet = this.textContent
                if excess
                    if this.textContent.length < excess
                        excess -= this.textContent.length
                        contentSnippet = ''
                    else if this.textContent.length >= excess
                        this.textContent = this.textContent.substr(
                            0, this.textContent.length - excess - 1
                        ) + '...'
                        excess = 0
                        contentSnippet = $wrapper.html()
                        if not contentSnippet
                            contentSnippet = this.textContent
                newContent = contentSnippet + newContent
            newContent
        _showExamples: ->
            ###
                Shows marked example codes directly in browser.

                **returns {$.Documentation}** - Returns the current instance.
            ###
            this.$domNodes.parent.find(':not(iframe)').contents().each (
                index, domNode
            ) =>
                if domNode.nodeName is this._options.showExample.domNodeName
                    match = domNode.textContent.match new window.RegExp(
                        this._options.showExample.pattern)
                    if match
                        $codeDomNode = $(domNode).next()
                        code = $codeDomNode.find(
                            this.$domNodes.codeWrapper
                        ).text()
                        code = $codeDomNode.text() if not code
                        try
                            if $.inArray(
                                match[2]?.toLowerCase(), ['javascript', 'js']
                            ) isnt -1
                                $codeDomNode.after $('<script>').attr(
                                    'type', 'text/javascript'
                                ).text code
                            else if match[2]? and $.inArray(
                                match[2].toLowerCase(), [
                                    'css', 'cascadingstylesheets'
                                    'stylesheets', 'sheets', 'style']
                            ) isnt -1
                                $codeDomNode.after $('<style>').attr(
                                    'type', 'text/css'
                                ).text code
                            else if match[2]? and $.inArray(
                                match[2].toLowerCase(), ['hidden']
                            ) isnt -1
                                $codeDomNode.after code
                            else
                                $codeDomNode.after $(
                                    this._options.showExample.htmlWrapper
                                ).append code
                        catch error
                            this.critical(
                                "Error while integrating code \"#{code}\": " +
                                "#{error}")
            this.fireEvent 'examplesLoaded'
            this

    # endregion

    # region handle $ extending

    $.Documentation = -> $.Tools().controller Documentation, arguments
    $.Documentation.class = Documentation

    # endregion

# endregion

# region dependencies

if this.require?
    this.require.scopeIndicator = 'jQuery.Documentation'
    this.require [['jQuery.Website', 'jquery-website-1.0.coffee']], main
else
    main this.jQuery

# endregion

# region modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
