#
# * Licensed to the Apache Software Foundation (ASF) under one
# * or more contributor license agreements.  See the NOTICE file
# * distributed with this work for additional information
# * regarding copyright ownership.  The ASF licenses this file
# * to you under the Apache License, Version 2.0 (the
# * "License"); you may not use this file except in compliance
# * with the License.  You may obtain a copy of the License at
# *
# * http://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing,
# * software distributed under the License is distributed on an
# * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# * KIND, either express or implied.  See the License for the
# * specific language governing permissions and limitations
# * under the License.
#

window.app =
  # Application Constructor
  initialize: ->
    @bindEvents()
    return

  # Bind Event Listeners
  #
  # Bind any events that are required on startup. Common events are:
  # 'load', 'deviceready', 'offline', and 'online'.
  bindEvents: ->
    document.addEventListener "deviceready", @onDeviceReady, false
    return

  # deviceready Event Handler
  #
  # The scope of 'this' is the event. In order to call the 'receivedEvent'
  # function, we must explicity call 'app.receivedEvent(...);'
  onDeviceReady: ->
    # Create navigation models
    window.router = new AppRouter()
    # window.navigation = new Navigation()

    # Start backbone history
    Backbone.history.start()

    $.support.cors = true

    # Bind window title to backbone router
    # ko.applyBindings(new NavbarViewModel(window.navigation), $('#navbar')[0])
    # ko.applyBindings(new DashMenuViewModel(window.navigation), $('#dash-menu')[0])
    return

  # Update DOM on a Received Event
  receivedEvent: (id) ->

    return

# Backbone router
class window.AppRouter extends Backbone.Router
  routes:
    ''              : 'home'
    'step1'         : 'step1'
    'step2'         : 'step2'
    'step3'         : 'step3'
    'social'        : 'social'
    'candidate/:id' : 'candidate'
 
  home: ->
    html = kb.renderTemplate('home-template', kb.viewModel())
    $('#main-section').html(html)
    # $('#carousel').owlCarousel({
    #   items: 1
    #   itemsDesktop: false
    #   itemsDesktopSmall: false
    #   itemsTablet: false
    #   itemsMobile: false
    #   pagination: true
    #   addClassActive: true
    # })
    #navigation.display 'Inicio', 'home'
    a = new Date()
    b = new Date('2014-05-25')
    $('#days-left').html(Math.max(0, b.getDate() - a.getDate() + 1))
    NProgress.done()

  step1: ->
    html = kb.renderTemplate('step1-template', kb.viewModel())
    $('#main-section').fadeOut 'fast', ->
      $('#main-section').html(html)
      $('#main-section').fadeIn()
      NProgress.done()
      $('#cbp-qtrotator').cbpQTRotator();

  step2: ->
    html = kb.renderTemplate('step2-template', kb.viewModel())
    $('#main-section').fadeOut 'fast', ->
      $('#main-section').html(html)
      $('#main-section').fadeIn()
      NProgress.done()

  step3: ->
    html = kb.renderTemplate('step3-template', kb.viewModel())
    $('#main-section').fadeOut 'fast', ->
      $('#main-section').html(html)
      $('#main-section').fadeIn()
      NProgress.done()

  social: ->
    html = kb.renderTemplate('social-template', kb.viewModel())
    $('#main-section').fadeOut 'fast', ->
      $('#main-section').html(html)
      $('#main-section').fadeIn()
      NProgress.done()

    # Fetch APP timeline
    twitterFetcher.fetch('463040140948946944', 'presidentate_social', 10, true, true, false);

  candidate: (id) ->
    html = kb.renderTemplate("candidate-template-#{id}", kb.viewModel())
    $('#main-section').fadeOut 'fast', ->
      $('#main-section').html(html)
      $('#main-section').fadeIn()
      NProgress.done()

      if id is "1"
        # Fetch Lopez timeline
        twitterFetcher.fetch('463050828471734272', 'candidate-social-1', 10, true, true, false);

      if id is "2"
        # Fetch Penalosa timeline
        twitterFetcher.fetch('463050431355043841', 'candidate-social-2', 10, true, true, false);

      if id is "3"
        # Fetch Ramirez timeline
        twitterFetcher.fetch('463050259950600192', 'candidate-social-3', 10, true, true, false);

      if id is "4"
        # Fetch Santos timeline
        twitterFetcher.fetch('463050579292348417', 'candidate-social-4', 10, true, true, false);

      if id is "5"
      # Fetch Zuluaga timeline
        twitterFetcher.fetch('463039419788709888', 'candidate-social-5', 10, true, true, false);


  before: ->
    NProgress.start()
    $("*").animate({ scrollTop: 0 }, 0);

  after: ->
    $(document).foundation()

# Application entry point
$ ->
  $('.video').fitVids();

$(document).on 'click', "[data-bypass]", (e) ->
  return false

$(document).on 'click', "#place-query", (e) ->
  $id = $('#user-id').val()
  $("#q-error").hide()
  $("#q-success").hide()
  $.ajax({  
    type: 'GET'
    url: "http://hackatonpresidencial.herokuapp.com/booths/#{$id}.jsonp?callback=onSucess" 
    contentType: "application/json"
    dataType: 'jsonp'  
    crossDomain: true
    success: (res) ->
      console.log res
      $("#q-1").val(res[0])
      $("#q-1").val(res[1])
      $("#q-1").val(res[2])
      $("#q-1").val(res[3])
      $("#q-1").val(res[5])
      $("#q-success").fadeIn('fast')
    error: ->
      $("#q-error").fadeIn('fast')
    complete: ->
  });

$(document).on 'click', "a[href^='/']:not([data-bypass])", (e) ->
    href = $(@).attr('href')
    protocol = "#{@protocol}//"

    if href.slice(protocol.length) isnt protocol
      e.preventDefault()
      router.navigate(href, true)
