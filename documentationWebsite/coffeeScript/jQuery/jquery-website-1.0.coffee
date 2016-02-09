#!/usr/bin/env coffee
# -*- coding: utf-8 -*-

# region header

###
[Project page](http://torben.website/jQuery-website)

This module provides common logic for the whole web page.

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

# region plugins/classes

    class Website extends $.Tools.class
        ###This plugin holds all needed methods to extend a whole website.###

    # region properties

        ###
            **__name__ {String}**
            Holds the class name to provide inspection features.
        ###
        __name__: 'Website'

    # endregion

    # region public methods

        # region special

        initialize: (
            options={}, @_parentOptions={
                logging: false
                domNodeSelectorPrefix: 'body.{1}'
                onViewportMovesToTop: $.noop()
                onViewportMovesAwayFromTop: $.noop()
                onChangeToLargeMode: $.noop()
                onChangeToMediumMode: $.noop()
                onChangeToSmallMode: $.noop()
                onChangeToExtraSmallMode: $.noop()
                onChangeMediaQueryMode: $.noop()
                onSwitchSection: $.noop()
                onStartUpAnimationComplete: $.noop()
                knownScrollEventNames:
                    'scroll mousedown wheel DOMMouseScroll mousewheel keyup ' +
                    'touchmove'
                switchToManualScrollingIndicator: (event) -> (
                    event.which > 0 or event.type is 'mousedown' or
                    event.type is 'mousewheel' or event.type == 'touchmove')
                additionalPageLoadingTimeInMilliseconds: 0
                trackingCode: null
                mediaQueryCssIndicator: [
                    ['extraSmall', 'xs'], ['small', 'sm'], ['medium', 'md']
                    ['large', 'lg']
                ],
                domNode:
                    mediaQueryIndicator: '<div class="media-query-indicator">'
                    top: '> div.navbar-wrapper'
                    scrollToTopButton: 'a[href="#top"]'
                    startUpAnimationClassPrefix:
                        '.website-start-up-animation-number-'
                    windowLoadingCover: 'div.website-window-loading-cover'
                    windowLoadingSpinner:
                        'div.website-window-loading-cover > div'
                startUpFadeIn:
                    easing: 'swing'
                    duration: 'slow'
                windowLoadingCoverFadeOut:
                    easing: 'swing'
                    duration: 'slow'
                startUpAnimationElementDelayInMiliseconds: 100
                windowLoadingSpinner:
                    lines: 9 # The number of lines to draw
                    length: 23 # The length of each line
                    width: 11 # The line thickness
                    radius: 40 # The radius of the inner circle
                    corners: 1 # Corner roundness (0..1)
                    rotate: 75 # The rotation offset
                    color: '#000' # #rgb or #rrggbb
                    speed: 1.1 # Rounds per second
                    trail: 58 # Afterglow percentage
                    shadow: false # Whether to render a shadow
                    hwaccel: false # Whether to use hardware acceleration
                    className: 'spinner' # CSS class to assign to the spinner
                    zIndex: 2e9 # The z-index (defaults to 2000000000)
                    top: 'auto' # Top position relative to parent in px
                    left: 'auto' # Left position relative to parent in px
                activateLanguageSupport: true
                language: {}
                scrollToTop:
                    inLinearTime: true
                    options: duration: 'normal'
                    button:
                        slideDistanceInPixel: 30
                        showAnimation: duration: 'normal'
                        hideAnimation: duration: 'normal'
                domain: 'auto'
            }, @startUpAnimationIsComplete=false, @currentSectionName=null
            @_viewportIsOnTop=false, @_currentMediaQueryMode=''
            @languageHandler=null, @__analyticsCode={
                initial: '''
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new window.Date();
a=s.createElement(o),m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;
m.parentNode.insertBefore(a,m)})(
window,document,'script','//www.google-analytics.com/analytics.js','ga');
window.ga('create', '{1}', '{2}');
window.ga('set', 'anonymizeIp', true);
window.ga('send', 'pageview', {page: '{3}'});'''
                sectionSwitch: "window.ga('send', 'pageview', {page: '{1}'});"
                event: '''
window.ga(
    'send', 'event', eventCategory, eventAction, eventLabel, eventValue,
    eventData);
'''
            }
        ) ->
            ###
                Initializes the interactive web application.

                **options {Object}**    - An options object.

                **returns {$.Website}** - Returns the current instance.
            ###
            if not this.currenSectionName?
                if window.location.hash
                    this.currentSectionName = window.location.hash.substring(
                        '#'.length)
                else
                    this.currenSectionName = 'home'
            # Wrap event methods with debounceing handler.
            this._onViewportMovesToTop = this.debounce(
                this.getMethod this._onViewportMovesToTop)
            this._onViewportMovesAwayFromTop = this.debounce(
                this.getMethod this._onViewportMovesAwayFromTop)
            this._options = $.extend(
                true, {}, this._parentOptions, this._options)
            super options
            this.$domNodes = this.grabDomNode this._options.domNode
            this.disableScrolling()._options.windowLoadingCoverFadeOut.always =
                this.getMethod this._handleStartUpEffects
            this.$domNodes.windowLoadingSpinner.spin(
                this._options.windowLoadingSpinner)
            this._bindScrollEvents().$domNodes.parent.show()
            onLoaded = =>
                this.windowLoaded = true
                this._removeLoadingCover()
            if window.less?
                window.less.pageLoadFinished.then onLoaded
            else
                this.on this.$domNodes.window, 'load', onLoaded
            this._addNavigationEvents()._addMediaQueryChangeEvents(
            )._triggerWindowResizeEvents()._handleAnalyticsInitialisation()
            if not this._options.language.logging?
                this._options.language.logging = this._options.logging
            if this._options.activateLanguageSupport
                this.languageHandler = $.Lang this._options.language
            this

        # endregion

        disableScrolling: ->
            ###
                This method disables scrolling on the given web view.

                **returns {$.Website}** - Returns the current instance.
            ###
            this.$domNodes.parent.addClass('disable-scrolling').on(
                'touchmove', (event) -> event.preventDefault())
            this
        enableScrolling: ->
            ###
                This method disables scrolling on the given web view.

                **returns {$.Website}** - Returns the current instance.
            ###
            this.off(
                this.$domNodes.parent.removeClass 'disable-scrolling'
                'touchmove')
            this
        triggerAnalyticsEvent: ->
            ###
                Triggers an analytics event. All given arguments are forwarded
                to configured analytics event code to defined their environment
                variables.

                **returns {$.Website}**  - Returns the current instance.
            ###
            if this._options.trackingCode? and
            this._options.trackingCode isnt '__none__' and
            window.location.hostname isnt 'localhost'
                this.debug(
                    "Run analytics code: \"#{this.__analyticsCode.event}\" " +
                    'with arguments:')
                this.debug arguments
                try
                    (new window.Function(
                        'eventCategory', 'eventAction', 'eventLabel'
                        'eventData', 'eventValue', this.__analyticsCode.event
                    )).apply this, arguments
                catch exception
                    this.warn(
                        'Problem in google analytics event code snippet: {1}'
                        exception)
            this

    # endregion

    # region protected methods

        # region event

        _onViewportMovesToTop: ->
            ###
                This method triggers if the viewport moves to top.

                **returns {$.Website}** - Returns the current instance.
            ###
            if this.$domNodes.scrollToTopButton.css('visibility') is 'hidden'
                this.$domNodes.scrollToTopButton.css 'opacity', 0
            else
                this._options.scrollToTop.button.hideAnimation.always = =>
                    this.$domNodes.scrollToTopButton.css
                        bottom: '-=' +
                        this._options.scrollToTop.button.slideDistanceInPixel
                this.$domNodes.scrollToTopButton.finish().animate({
                    bottom: '+=' +
                    this._options.scrollToTop.button.slideDistanceInPixel
                    opacity: 0
                }, this._options.scrollToTop.button.hideAnimation)
            this
        _onViewportMovesAwayFromTop: ->
            ###
                This method triggers if the viewport moves away from top.

                **returns {$.Website}** - Returns the current instance.
            ###
            if this.$domNodes.scrollToTopButton.css('visibility') is 'hidden'
                this.$domNodes.scrollToTopButton.css 'opacity', 1
            else
                this.$domNodes.scrollToTopButton.finish().css(
                    bottom: '+=' +
                    this._options.scrollToTop.button.slideDistanceInPixel
                    display: 'block', opacity: 0
                ).animate({
                    bottom: '-=' +
                    this._options.scrollToTop.button.slideDistanceInPixel
                    queue: false, opacity: 1
                }, this._options.scrollToTop.button.showAnimation)
            this
        _onChangeMediaQueryMode: (oldMode, newMode) ->
            ###
                This method triggers if the responsive design switches to
                another mode.

                **oldMode {String}**    - Saves the previous mode.

                **newMode {String}**    - Saves the new mode.

                **returns {$.Website}** - Returns the current instance.
            ###
            this
        _onChangeToLargeMode: (oldMode, newMode) ->
            ###
                This method triggers if the responsive design switches to large
                mode.

                **oldMode {String}**    - Saves the previous mode.

                **newMode {String}**    - Saves the new mode.

                **returns {$.Website}** - Returns the current instance.
            ###
            this
        _onChangeToMediumMode: (oldMode, newMode) ->
            ###
                This method triggers if the responsive design switches to
                medium mode.

                **oldMode {String}**    - Saves the previous mode.

                **newMode {String}**    - Saves the new mode.

                **returns {$.Website}** - Returns the current instance.
            ###
            this
        _onChangeToSmallMode: (oldMode, newMode) ->
            ###
                This method triggers if the responsive design switches to small
                mode.

                **oldMode {String}**    - Saves the previous mode.

                **newMode {String}**    - Saves the new mode.

                **returns {$.Website}** - Returns the current instance.
            ###
            this
        _onChangeToExtraSmallMode: (oldMode, newMode) ->
            ###
                This method triggers if the responsive design switches to extra
                small mode.

                **oldMode {String}**    - Saves the previous mode.

                **newMode {String}**    - Saves the new mode.

                **returns {$.Website}** - Returns the current instance.
            ###
            this
        _onSwitchSection: (sectionName) ->
            ###
                This method triggers if we change the current section.

                **sectionName {String}** - Contains the new section name.

                **returns {$.Website}**  - Returns the current instance.
            ###
            if(
                this._options.trackingCode? and
                this._options.trackingCode isnt '__none__' and
                window.location.hostname isnt 'localhost' and
                this.currentSectionName isnt sectionName
            )
                this.currentSectionName = sectionName
                this.debug(
                    'Run analytics code: "' +
                    "#{this.__analyticsCode.sectionSwitch}\""
                    this.currentSectionName)
                try
                    (new window.Function(this.stringFormat(
                        this.__analyticsCode.sectionSwitch
                        this.currentSectionName
                    )))()
                catch exception
                    this.warn(
                        'Problem in analytics section switch code snippet: {1}'
                        exception)
            this
        _onStartUpAnimationComplete: ->
            ###
                This method is complete if last startup animation was
                initialized.

                **returns {$.Website}** - Returns the current instance.
            ###
            this.startUpAnimationIsComplete = true
            this

        # endregion

        # region helper

        _addMediaQueryChangeEvents: ->
            ###
                This method adds triggers for responsive design switches.

                **returns {$.Website}** - Returns the current instance.
            ###
            this.on this.$domNodes.window, 'resize', this.getMethod(
                this._triggerWindowResizeEvents)
            this
        _triggerWindowResizeEvents: ->
            ###
                This method triggers if the responsive design switches its
                mode.

                **returns {$.Website}** - Returns the current instance.
            ###
            $.each this._options.mediaQueryCssIndicator, (key, value) =>
                this.$domNodes.mediaQueryIndicator.prependTo(
                    this.$domNodes.parent
                ).addClass "hidden-#{value[1]}"
                if(
                    this.$domNodes.mediaQueryIndicator.is(':hidden') and
                    value[0] isnt this._currentMediaQueryMode
                )
                    this.fireEvent.apply(
                        this, [
                            'changeMediaQueryMode', false, this,
                            this._currentMediaQueryMode, value[0]
                        ].concat this.argumentsObjectToArray arguments
                    )
                    this.fireEvent.apply(
                        this, [
                            this.stringFormat(
                                'changeTo{1}Mode',
                                this.stringCapitalize(value[0])
                            ), false, this, this._currentMediaQueryMode,
                            value[0]
                        ].concat this.argumentsObjectToArray arguments
                    )
                    this._currentMediaQueryMode = value[0]
                this.$domNodes.mediaQueryIndicator.removeClass(
                    "hidden-#{value[1]}")
            this
        _bindScrollEvents: ->
            ###
                This method triggers if view port arrives at special areas.

                **returns {$.Website}** - Returns the current instance.
            ###
            # Stop automatic scrolling if the user wants to scroll manually.
            $scrollTarget = $('body, html').add this.$domNodes.window
            $scrollTarget.on(
                this._options.knownScrollEventNames, (event) =>
                    if this._options.switchToManualScrollingIndicator event
                        $scrollTarget.stop true
            )
            this.on this.$domNodes.window, 'scroll', =>
                if this.$domNodes.window.scrollTop()
                    if this._viewportIsOnTop
                        this._viewportIsOnTop = false
                        this.fireEvent.apply this, [
                            'viewportMovesAwayFromTop', false, this
                        ].concat this.argumentsObjectToArray arguments
                else if not this._viewportIsOnTop
                    this._viewportIsOnTop = true
                    this.fireEvent.apply this, [
                        'viewportMovesToTop', false, this
                    ].concat this.argumentsObjectToArray arguments
            if this.$domNodes.window.scrollTop()
                this._viewportIsOnTop = false
                this.fireEvent.apply this, [
                    'viewportMovesAwayFromTop', false, this
                ].concat this.argumentsObjectToArray arguments
            else
                this._viewportIsOnTop = true
                this.fireEvent.apply this, [
                    'viewportMovesToTop', false, this
                ].concat this.argumentsObjectToArray arguments
            this
        _removeLoadingCover: ->
            ###
                This method triggers after window is loaded.

                **returns {$.Website}** - Returns the current instance.
            ###
            window.setTimeout(=>
                # Hide startup animation dom nodes to show them step by step.
                $(this.stringFormat(
                    '[class^="{1}"], [class*=" {1}"]'
                    this.sliceDomNodeSelectorPrefix(
                        this._options.domNode.startUpAnimationClassPrefix
                    ).substr 1)
                ).hide()
                if this.$domNodes.windowLoadingCover.length
                    this.enableScrolling(
                    ).$domNodes.windowLoadingCover.fadeOut(
                        this._options.windowLoadingCoverFadeOut)
                else
                    this._options.windowLoadingCoverFadeOut.always()
            , this._options.additionalPageLoadingTimeInMilliseconds)
            this
        _handleStartUpEffects: (elementNumber) ->
            ###
                This method handles the given start up effect step.

                **elementNumber {Number}** - The current start up step.

                **returns {$.Website}**    - Returns the current instance.
            ###
            # Stop and delete spinner instance.
            this.$domNodes.windowLoadingSpinner.spin false
            elementNumber = 1 if not $.isNumeric elementNumber
            if $(this.stringFormat(
                '[class^="{1}"], [class*=" {1}"]'
                this.sliceDomNodeSelectorPrefix(
                    this._options.domNode.startUpAnimationClassPrefix
                ).substr 1)
            ).length
                window.setTimeout((=>
                    lastElementTriggered = false
                    this._options.startUpFadeIn.always = =>
                        if lastElementTriggered
                            this.fireEvent 'startUpAnimationComplete'
                    $(
                        this._options.domNode.startUpAnimationClassPrefix +
                        elementNumber
                    ).fadeIn this._options.startUpFadeIn
                    if $(this._options.domNode.startUpAnimationClassPrefix +
                         (elementNumber + 1)).length
                        this._handleStartUpEffects elementNumber + 1
                    else
                        lastElementTriggered = true
                ), this._options.startUpAnimationElementDelayInMiliseconds)
            else
                this.fireEvent 'startUpAnimationComplete'
            this
        _addNavigationEvents: ->
            ###
                This method adds triggers to switch section.

                **returns {$.Website}** - Returns the current instance.
            ###
            this.$domNodes.window.hashchange(=>
                if this.startUpAnimationIsComplete
                    this.fireEvent(
                        'switchSection', false, this
                        window.location.hash.substring '#'.length))
            this._handleScrollToTopButton()
        _handleScrollToTopButton: ->
            ###
                Adds trigger to scroll top buttons.

                **returns {$.Website}** - Returns the current instance.
            ###
            this.on(
                this.$domNodes.scrollToTopButton, 'click', (event) =>
                    event.preventDefault()
                    this._scrollToTop()
            )
            this
        _scrollToTop: (onAfter=$.noop()) ->
            ###
                Scrolls to top of page. Runs the given function after viewport
                arrives.

                **onAfter {Function}**  - Callback to call after effect has
                                          finished.

                **returns {$.Website}** - Returns the current instance.
            ###
            this._options.scrollToTop.options.onAfter = onAfter
            # NOTE: This is a workaround to avoid a bug in "jQuery.scrollTo()"
            # expecting this property exists.
            window.document.body = $('body')[0]
            if this._options.scrollToTop.inLinearTime
                distanceToTopInPixel = this.$domNodes.window.scrollTop()
                # Scroll four times faster as we have distance to top.
                this._options.scrollToTop.options.duration =
                    distanceToTopInPixel / 4
                $(window).scrollTo(
                    {top: "-=#{distanceToTopInPixel}", left: '+=0'}
                    this._options.scrollToTop.options)
            else
                $(window).scrollTo(
                    {top: 0, left: 0}, this._options.scrollToTop.options)
            this
        _handleAnalyticsInitialisation: ->
            ###
                Executes the page tracking code.

                **returns {$.Website}** - Returns the current instance.
            ###
            if this._options.trackingCode? and
            this._options.trackingCode isnt '__none__' and
            window.location.hostname isnt 'localhost'
                this.debug(
                    "Run analytics code: \"#{this.__analyticsCode.initial}\""
                    this._options.trackingCode, this._options.domain
                    this.currentSectionName)
                try
                    (new window.Function(this.stringFormat(
                        this.__analyticsCode.initial
                        this._options.trackingCode, this._options.domain
                        this.currentSectionName
                    )))()
                catch exception
                    this.warn(
                        'Problem in analytics initial code snippet: {1}'
                        exception)
                this.on this.$domNodes.parent.find('a, button'), 'click', (
                    event
                ) =>
                    $domNode = $ event.target
                    this.triggerAnalyticsEvent(
                        this.currentSectionName, 'click', $domNode.text()
                        event.data or {}, $domNode.attr(
                            'website-analytics-value'
                        ) or 1)
            this

        # endregion

    # endregion

    # region handle $ extending

    $.Website = -> $.Tools().controller Website, arguments
    $.Website.class = Website

    # endregion

# endregion

# region dependencies

if this.require?
    this.require.scopeIndicator = 'jQuery.Website'
    this.require [
        ['jQuery.Tools', 'jquery-tools-1.0.coffee']
        ['jQuery.scrollTo', 'jquery-scrollTo-2.1.0']
        ['jQuery.fn.spin', 'jquery-spin-2.0.1']
        ['jQuery.fn.hashchange', 'jquery-observeHashChange-1.0']
        ['jQuery.Lang', 'jquery-lang-1.0.coffee']
    ], main
else
    main this.jQuery

# endregion

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
