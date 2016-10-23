_ = require('lodash')

angular.module('AltexoApp')

.controller 'StreamCtrl',
($scope, $location, $timeout, $routeParams, $mdToast, $localStorage, $mdSidenav, $log, AlRoomsService, RpcError) ->

  $scope.$storage = $localStorage.$default {
    nickname: 'John Doe'
  }
  $scope.textMessage = ''

  $scope.controls = {
    local: { audio: true, video: true }
    remote: { audio: true, video: true }
  }

  $scope.toggleChat = () ->
    $mdSidenav('right')
      .toggle()
      .then ->
        $log.debug('toggle ' + 'right' + ' is done')
    return

  $scope.chat.ensureConnected()
  .then -> $scope.chat.setAlias($localStorage.nickname)
  .then -> $scope.chat.openRoom($routeParams.room)
  .then ->
    # add room to used
    AlRoomsService.roomUsed($routeParams.room)

    endToastAdds = $scope.chat.$on 'add-user', (users) ->
      users.forEach (user) ->
        $mdToast.show($mdToast.simple()
          .textContent("#{user.name} entered this room."))

    endToastRemoves = $scope.chat.$on 'remove-user', (users) ->
      users.forEach (user) ->
        $mdToast.show($mdToast.simple()
          .textContent("#{user.name} leaved this room."))

    endRedirects = $scope.chat.$on 'room-destroyed', ->
      $mdToast.show($mdToast.simple()
        .textContent('Room was destroyed by initiator.'))
      $location.path('/')

    # TODO: handle leaving room on closing
    $scope.$on '$destroy', ->
      endToastAdds()
      endToastRemoves()
      endRedirects()
      $scope.chat.leaveRoom()

    return
  .catch (error) ->
    if error.code == RpcError.ONLY_TWO_PERSONS_ALLOWED
      $mdToast.show($mdToast.simple()
        .textContent('Sorry, only one guest may view this stream at a time. Currently the room is busy.'))
    return

  $scope.viewLink = ->
    $location.absUrl().replace(/([^:\/])\/.+/,
      "$1/room/#{$routeParams.room}")

  $scope.onLogoClick = ->
    $location.path('/')
    return

  $scope.setChatAlias = (value) ->
    $scope.chat.setAlias(value)

  $scope.setChatAlias = _($scope.setChatAlias).debounce(1750).value()

  $scope.sendMessage = (text) ->
    $scope.chat.sendMessage(text)
    $scope.textMessage = ''
