/*
  
A super-simple external template loader for KnockoutJS.

Loads the template data from the server, rather than looking in <script> tags.

Usage:

Simplest: just include this file, and it will look for templates at:

  ``/templates/<template-name>.html``

If you want to change the settings:

  require(['knockout/external-templates'], function(tmpl) {
    tmpl.location = 'http://example.com/__templates__/';
    tmpl.prefix = 'template_'
    tmpl.suffix = '.htm';
    
    tmpl.notFound = function(name, location) {
      return 'Oops. Could not find ' + name + ' at ' + location';
    };
  });

``.location`` may be a different server, subject to CORS.


*/

(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define(['jquery', 'knockout'], function ($, ko) {
            return factory($, ko);
        });
    } else {
        // Browser globals
        factory(root.$, root.ko);
    }
}(this, function ($, ko) {
  
  ko.externalTemplateEngine = function() {
    this.allowTemplateRewriting = false;
    this.location = '/templates/';
    this.prefix = '';
    this.suffix = '.html';
    
    // How to use a loading template?
    this.loading = '<div class="loading-template">Loading...</div>';
    
    this.notFound = function(name, location) {
      if (console.error) {
        console.error('Missing template:', name);
      }
      return [
        '<div class="unknown-template">Unable to load template ',
        '<a href="', location, '">', name, '</a>',
        ' from the server.</div>'
      ].join('');
    }
  }
  
  var cachedTemplates = {};
  
  ko.externalTemplateEngine.prototype = new ko.templateEngine();
  ko.externalTemplateEngine.prototype.constructor = ko.externalTemplateEngine;
  ko.externalTemplateEngine.prototype.renderTemplateSource = function(templateSource, bindingContext, options) {
    return ko.utils.parseHtmlFragment(templateSource);
  }
  ko.externalTemplateEngine.prototype.makeTemplateSource = function(template, templateDocument) {
    var templatePath = this.location + this.prefix + template + this.suffix;
    if (undefined === cachedTemplates[template]) {
      $.ajax({
        type: 'GET',
        url: templatePath,
        success: function(data) {
          cachedTemplates[template] = data;
        },
        async: false
      });
    }
    
    var templateData = cachedTemplates[template];
    if (undefined === templateData) {
      templateData = this.notFound(template, templatePath);
    }
    
    return templateData;
  }
  
  ko.externalTemplateEngine.instance = new ko.externalTemplateEngine();
  ko.setTemplateEngine(ko.externalTemplateEngine.instance);
  
  return ko.externalTemplateEngine.instance;
}));