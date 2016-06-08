# TODO - consider using collection hooks instead of observe
# https://atmospherejs.com/matb33/collection-hooks

class @Mongo2ES
  constructor: (@options, @transform, @copyAlreadyExistingData = false) ->
    self = @
    @verbose = self.options.verbose or process.env.MONGO2ES_VERBOSE?
    self.options.collectionName = self.getCollection(self.options.collectionName)
    self.watcher = self.options.collectionName.find().observe(
      added: (newDocument) ->
        if self.copyAlreadyExistingData
          if self.transform? and _.isFunction(self.transform)
            if self.transform(newDocument) is false then return
            else newDocument = self.transform(newDocument)
          self.addToES(self.options.collectionName, self.options.ES, newDocument)

      changed: (newDocument, oldDocument) ->
        if self.transform? and _.isFunction(self.transform)
          if self.transform(newDocument) is false then return
          else newDocument = self.transform(newDocument)
        self.updateToES(self.options.collectionName, self.options.ES, newDocument, oldDocument)

      removed: (oldDocument) ->
        if self.transform? and _.isFunction(self.transform)
          if self.transform() is false then return
        self.removeESdocument(self.options.ES, oldDocument._id)
    )
    self.copyAlreadyExistingData = true

  getCollection: (collectionName) ->
    if _.isString(collectionName) then return new Mongo.Collection collectionName
    else return collectionName

  stopWatch: ->
    self = @
    self.watcher.stop()
    self.watcher

  getStatusForES: (ES) ->
    console.log "checking connectivity with ElasticSearch on #{ES.host}"
    options = { data: '/' }
    if ES.auth then options.auth = ES.auth
    try
      response = HTTP.get(ES.host, options)
    catch e
      log.error(e)
      return error = e
    return response

  addToES: (collectionName, ES, newDocument) ->
    log.info("adding doc #{newDocument._id} to ES")
    url = "#{ES.host}/#{ES.index}/#{ES.type}/#{newDocument._id}"
    query = _.omit(newDocument, '_id')
    options = { data: query }
    if ES.auth then options.auth = ES.auth
    if @verbose
      console.log url
      console.log query
    try
      response = HTTP.post(url, options)
    catch e
      log.error(e)
      return e
    return response

  updateToES: (collectionName, ES, newDocument, oldDocument) ->
    if newDocument._id isnt oldDocument._id
      log.info "document ID #{oldDocument._id} was changed to #{newDocument._id}"
      @removeESdocument(ES, oldDocument._id)
    log.info "updating doc #{newDocument._id} to ES"
    url = "#{ES.host}/#{ES.index}/#{ES.type}/#{newDocument._id}"
    query = _.omit(newDocument, '_id')
    options = { data: query }
    if ES.auth then options.auth = ES.auth
    if @verbose
      console.log url
      console.log query
    try
      response = HTTP.post(url, options)
    catch e
      log.error(e)
      return e
    return response

  removeESdocument: (ES, documentID) ->
    log.info "removing doc #{documentID} from ES"
    url = "#{ES.host}/#{ES.index}/#{ES.type}/#{documentID}"
    options = {}
    if ES.auth then options.auth = ES.auth
    if @verbose
      console.log url
    try
      response = HTTP.del(url, options)
    catch e
      log.error(e)
      return e
    return response
