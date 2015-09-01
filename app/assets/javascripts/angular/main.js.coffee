@gradecraft = angular.module('gradecraft', [
  'angularMoment',
  'hideAfterFade',
  'ngAnimate',
  'ngDragDrop',
  'ngDraggable',
  'uiFx',
  '720kb.tooltips',
  'restangular',
  'ui.sortable',
  'ui.slider',
  'ui.router',
  'ng-rails-csrf',
  'ngResource',
  'ngAnimate',
  'froala',
  'templates',
  'smart-number',
  'fcsa-number',
  'helpers'
])

@gradecraft.config ($stateProvider, $urlRouterProvider, $locationProvider) ->

@gradecraft.config(['$compileProvider', ($compileProvider)->
  $compileProvider.debugInfoEnabled(false)
])

@gradecraft.directive "modalDialog", ->
  restrict: "E"
  scope:
    show: "="

  replace: true # Replace with the template below
  transclude: true # we want to insert custom content inside the directive
  link: (scope, element, attrs) ->
    scope.dialogStyle = {}
    scope.dialogStyle.width = attrs.width  if attrs.width
    scope.dialogStyle.height = attrs.height  if attrs.height
    scope.hideModal = ->
      scope.show = false
      return

    return

  template: "..." # See below

INTEGER_REGEXP = /^\-?\d+$/
@gradecraft.directive "integer", ->
  require: "ngModel"
  link: (scope, elm, attrs, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      if INTEGER_REGEXP.test(viewValue)
        # it is valid
        ctrl.$setValidity "integer", true
        viewValue
      else
        # it is invalid, return undefined (no model update)
        ctrl.$setValidity "integer", false
        'undefined'
    return

@gradecraft.directive 'gradeSchemeLowRange', [ 'GradeSchemeElementsService', (GradeSchemeElementsService)->
  require: "ngModel"
  link: (scope, elm, attrs, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      if GradeSchemeElementsService.checkLowRange(viewValue, attrs.index)
        # it is valid
        ctrl.$setValidity "gradeSchemeLowRange", true
        viewValue
      else
        # it is invalid, return undefined (no model update)
        ctrl.$setValidity "gradeSchemeLowRange", false
        'undefined'
    return
  ]

@gradecraft.directive 'gradeSchemeHighRange', [ 'GradeSchemeElementsService', (GradeSchemeElementsService)->
  require: "ngModel"
  link: (scope, elm, attrs, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      debugger
      if GradeSchemeElementsService.checkLowRange(viewValue, attrs.index)
        # it is valid
        ctrl.$setValidity "gradeSchemeLowRange", true
        viewValue
      else
        # it is invalid, return undefined (no model update)
        ctrl.$setValidity "gradeSchemeLowRange", false
        'undefined'
    return
  ]

@gradecraft.directive "collapseToggler", ->
  restrict : 'C',
  link: (scope, elm, attrs) ->
    elm.bind('click', (event)->
      if angular.element(event.target).hasClass('collapse-arrow')
        elm.siblings().toggleClass('collapsed')
        elm.toggleClass('collapsed')
    )
    return

@gradecraft.directive "collapseAllToggler", ->
  restrict : 'C',
  link: (scope, elm, attrs) ->
    elm.bind('click', ()->
      if elm.hasClass('collapsed')
        angular.element(".collapse-toggler.collapsed .collapse-arrow").click()
      else
        angular.element(".collapse-toggler").not(".collapsed").children(".collapse-arrow").click()
      elm.toggleClass('collapsed')
    )
    return

FLOAT_REGEXP = /^\-?\d+((\.|\,)\d+)?$/
@gradecraft.directive "smartFloat", ->
  require: "ngModel"
  link: (scope, elm, attrs, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      if FLOAT_REGEXP.test(viewValue)
        ctrl.$setValidity "float", true
        parseFloat viewValue.replace(",", ".")
      else
        ctrl.$setValidity "float", false
        `undefined`

    return

@gradecraft.directive "ngMax", ->
  require: "ngModel"
  link: (scope, elm, attr, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      value = viewValue
      #alert("value:" + value)
      max = scope.$eval(attr.ngMax)
      #alert("max:" + max)
      if value and value != "" and value > max
        ctrl.$setValidity "ngMax", false
        'undefined'
      else
        ctrl.$setValidity "ngMax", true
        value

    return

@gradecraft.directive "ngOnscreen", ->
  require: "ngModel"
  link: (scope, elm, attr, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      value = viewValue
      max = scope.$eval(attr.ngMax)
      if value and value != "" and value > max
        ctrl.$setValidity "ngMax", false
        'undefined'
      else
        ctrl.$setValidity "ngMax", true
        value

    return


@gradecraft.filter 'list', ['$sce', ($sce)->
  (input)->
    if typeof(input) == "string"
      return $sce.trustAsHtml(input)
    else if Array.isArray(input)
      return $sce.trustAsHtml("<ul><li>" + input.join('</li><li>') + "</li></ul>")
]
