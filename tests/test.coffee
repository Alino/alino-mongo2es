describe 'Mongo2ES', ->
  testCollection1 = new Mongo.Collection('testCollection1')
  testCollection2 = new Mongo.Collection('testCollection2')
  testCollection3 = new Mongo.Collection('testCollection3')
  testCollection4 = new Mongo.Collection('testCollection4')
  testCollection5 = new Mongo.Collection('testCollection5')
  testCollection6 = new Mongo.Collection('testCollection6')
  testCollection7 = new Mongo.Collection('testCollection7')
  testCollection9 = new Mongo.Collection('testCollection9')
  testCollection11 = new Mongo.Collection('testCollection11')
  testCollection12 = new Mongo.Collection('testCollection12')

  ESdefault = host: Meteor.settings.elasticsearchHost
  optionsDefault =
    collectionName: testCollection1
    ES:
      host: ESdefault.host
      index: 'admin'
      type: 'test'


  clearDB = ->
    testCollection1.remove({})
    testCollection2.remove({})
    testCollection3.remove({})
    testCollection4.remove({})
    testCollection5.remove({})
    testCollection6.remove({})
    testCollection7.remove({})
    testCollection9.remove({})
    testCollection11.remove({})
    testCollection12.remove({})

  beforeEach ->
    clearDB()


  describe 'getCollection', ->
    it 'should return meteor collection if it receives string', ->
      options = optionsDefault
      options.collectionName = 'testCollection10'
      x = new Mongo2ES(optionsDefault)
      collection = x.getCollection('testCollection8')
      expect(collection._collection).toBeDefined()
      expect(collection._name).toBe 'testCollection8'

    it 'should return meteor collection if it receives meteor collection', ->
      options = optionsDefault
      options.collectionName = testCollection9
      x = new Mongo2ES(optionsDefault)
      collection = x.getCollection(testCollection9)
      expect(collection._collection).toBeDefined()
      expect(collection._name).toBe 'testCollection9'

  describe 'getStatusForES', ->
    it 'should return ES statusCode 200', ->
      x = new Mongo2ES(optionsDefault)
      response = x.getStatusForES(optionsDefault.ES)
      expect(response.statusCode).toBeDefined
      expect(response.statusCode).toBe 200

    it 'should return an error if ES host unreachable', ->
      options =
        collectionName: testCollection2
        ES:
          host: "http://192.168.666.666:9200"
          index: 'admin'
          type: 'test'
      x = new Mongo2ES(options)
      response = x.getStatusForES(options.ES)
      expect(response.error).toBeDefined

  describe 'addToES', ->
    it 'should save document to ES', (done) ->
      options = optionsDefault
      options.collectionName = testCollection3
      x = new Mongo2ES(options)
      testCollection3.find().observe(
        added: (newDocument) ->
          expect(newDocument._id).toBe 'tvoj tatko'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('tvoj tatko')}"
          try
            result = HTTP.get(url)
            expect(result).toBeDefined()
            expect(result.data.found).toBe(true)
            expect(result.data._source).toEqual _.omit(newDocument, '_id')
          catch e
            console.error e
            expect(e).toBeUndefined()
          finally
            done()
      )
      testCollection3.insert({ _id: 'tvoj tatko', query: 'jebem' })


    it 'should save TRANSFORMED document to ES', (done) ->
      options = optionsDefault
      options.collectionName = testCollection7
      transform = (doc) ->
        doc.trans_query = "#{doc.query}_TRANSFORMED"
        return doc
      x = new Mongo2ES(options, transform)
      testCollection7.find().observe(
        added: (newDocument) ->
          expect(x.transform).toBeDefined()
          expect(newDocument._id).toBe 'transexual pojebany'
          expect(newDocument.query).toBe 'jebem'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('transexual pojebany')}"
          try
            result = HTTP.get(url)
            expect(result).toBeDefined()
            expect(result.data.found).toBe(true)
            transformedDocument = newDocument
            transformedDocument.trans_query = 'jebem_TRANSFORMED'
            expect(result.data._source).toEqual _.omit(transformedDocument, '_id')
          catch e
            console.error e
            expect(e).toBeUndefined()
          finally
            done()
      )
      testCollection7.insert({ _id: 'transexual pojebany', query: 'jebem' })

    it 'should copy already existing mongo data to ES if third parameter is true', (done) ->
      testCollection11.insert({ _id: 'toto tu uz bolo', query: 'jebem' })
      options = optionsDefault
      options.collectionName = testCollection11
      x = new Mongo2ES(options, undefined, true)
      testCollection11.find().observe(
        added: (newDocument) ->
          expect(x.transform).toBeUndefined()
          expect(x.copyAlreadyExistingData).toBe true
          expect(newDocument._id).toBe 'toto tu uz bolo'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('toto tu uz bolo')}"
          try
            result = HTTP.get(url)
            expect(result).toBeDefined()
            expect(result.data.found).toBe(true)
            expect(result.data._source).toEqual _.omit(newDocument, '_id')
          catch e
            console.error e
            expect(e).toBeUndefined()
          finally
            done()
      )

    it 'should not copy already existing mongo data to ES if third parameter is not defined', (done) ->
      testCollection12.insert({ _id: 'toto by tam nemalo byt', query: 'jebem' })
      options = optionsDefault
      options.collectionName = testCollection12
      x = new Mongo2ES(options)
      testCollection12.find().observe(
        added: (newDocument) ->
          expect(x.transform).toBeUndefined()
          expect().toBeUndefined()
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('toto by tam nemalo byt')}"
          try
            result = HTTP.get(url)
            expect(result).toBeUndefined()
          catch e
            expect(e).toBeDefined()
          finally
            done()
      )

  describe 'updateToES', ->
    it 'should update document in ES', (done) ->
      options = optionsDefault
      options.collectionName = testCollection6
      x = new Mongo2ES(options)
      testCollection6.insert({ _id: "42", query: 'jebem' })
      testCollection6.find().observe(
        changed: (newDocument, oldDocument) ->
          expect(newDocument._id).toBe '42'
          expect(newDocument.query).toBe 'nejebem'
          expect(oldDocument._id).toBe '42'
          expect(oldDocument.query).toBe 'jebem'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('42')}"
          try
            result = HTTP.get(url)
            expect(result).toBeDefined()
            expect(result.data._source).toEqual _.omit(newDocument, '_id')
          catch e
            expect(e).toBeUndefined()
          finally
            done()
      )
      testCollection6.update({ _id: "42" }, { $set: { query: 'nejebem' } })


  describe 'removeESdocument', ->
    it 'should remove document from ES', (done) ->
      options = optionsDefault
      options.collectionName = testCollection4
      x = new Mongo2ES(options)
      testCollection4.insert({ _id: 'jebem ja tvojho boha', query: 'jebem' })
      testCollection4.find().observe(
        removed: (oldDocument) ->
          expect(oldDocument._id).toBe 'jebem ja tvojho boha'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('jebem ja tvojho boha')}"
          try
            result = HTTP.get(url)
            expect(result).toBeUndefined()
          catch e
            expect(e).toBeDefined()
          finally
            done()
      )
      testCollection4.remove({ _id: 'jebem ja tvojho boha', query: 'jebem' })

  describe 'stopWatch', ->
    it 'should stop watching the collection', (done) ->
      options = optionsDefault
      options.collectionName = testCollection5
      x = new Mongo2ES(options)
      watcher = x.stopWatch()
      expect(watcher._stopped).toBe true
      testCollection5.find().observe(
        added: (newDocument) ->
          expect(newDocument._id).toBe 'tvoja mamka'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('tvoja mamka')}"
          try
            result = HTTP.get(url)
            expect(result).toBeUndefined()
          catch e
            expect(e).toBeDefined()
          finally
            done()
      )
      testCollection5.insert({ _id: 'tvoja mamka', query: 'jebem' })