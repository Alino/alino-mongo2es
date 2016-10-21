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
  testCollection13 = new Mongo.Collection('testCollection13')
  testCollection14 = new Mongo.Collection('testCollection14')
  testCollection15 = new Mongo.Collection('testCollection15')

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
    testCollection13.remove({})
    testCollection14.remove({})
    testCollection15.remove({})

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
          expect(newDocument._id).toBe 'kvak'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('kvak')}"
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
      testCollection3.insert({ _id: 'kvak', query: 'mnau' })


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
          expect(newDocument._id).toBe 'kvak'
          expect(newDocument.query).toBe 'mnau'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('kvak')}"
          try
            result = HTTP.get(url)
            expect(result).toBeDefined()
            expect(result.data.found).toBe(true)
            transformedDocument = newDocument
            transformedDocument.trans_query = 'mnau_TRANSFORMED'
            expect(result.data._source).toEqual _.omit(transformedDocument, '_id')
          catch e
            console.error e
            expect(e).toBeUndefined()
          finally
            done()
      )
      testCollection7.insert({ _id: 'kvak', query: 'mnau' })

    it 'should skip creating the document in ES if transform function returns false', (done) ->
      options = optionsDefault
      options.collectionName = testCollection13
      transform = (doc) -> return false
      x = new Mongo2ES(options, transform)
      testCollection13.find().observe(
        added: (newDocument) ->
          expect(x.transform).toBeDefined()
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('neprujdesdal')}"
          try
            result = HTTP.get(url)
            expect(result).toBeUndefined()
          catch e
            expect(e).toBeDefined()
          finally
            done()
      )
      testCollection13.insert({ _id: 'neprujdesdal', query: 'gandalf huli travu' })

    it 'should copy already existing mongo data to ES if third parameter is true', (done) ->
      testCollection11.insert({ _id: 'toto tu uz bolo', query: 'mnau' })
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
      testCollection12.insert({ _id: 'toto by tam nemalo byt', query: 'kvak' })
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
      testCollection6.insert({ _id: "42", query: 'kvak' })
      testCollection6.find().observe(
        changed: (newDocument, oldDocument) ->
          expect(newDocument._id).toBe '42'
          expect(newDocument.query).toBe 'mnau'
          expect(oldDocument._id).toBe '42'
          expect(oldDocument.query).toBe 'kvak'
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
      testCollection6.update({ _id: "42" }, { $set: { query: 'mnau' } })

    it 'should skip updating the document in ES if transform function returns false', (done) ->
      options = optionsDefault
      options.collectionName = testCollection14
      testCollection14.insert({ _id: 'neprujdesdal_update', query: 'gandalf huli kravu' })
      doc = testCollection14.findOne({ _id: 'neprujdesdal_update' })
      Mongo2ES::addToES(testCollection14, options.ES, doc)
      transform = (doc) -> return false
      x = new Mongo2ES(options, transform)
      testCollection14.find().observe(
        changed: (newDocument, oldDocument) ->
          expect(x.transform).toBeDefined()
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('neprujdesdal_update')}"
          try
            result = HTTP.get(url)
            expect(oldDocument.query).toBe('gandalf huli kravu')
            expect(newDocument.query).toBe('gandalf huli travu')
            expect(result).toBeDefined()
            expect(result.data._source.query).toBe('gandalf huli kravu')
          catch e
            expect(e).toBeUndefined()
          finally
            done()
      )
      testCollection14.update({ _id: 'neprujdesdal_update' }, { $set: { query: 'gandalf huli travu' } })


  describe 'removeESdocument', ->
    it 'should remove document from ES', (done) ->
      options = optionsDefault
      options.collectionName = testCollection4
      x = new Mongo2ES(options)
      testCollection4.insert({ _id: 'kvak', query: 'mnau' })
      testCollection4.find().observe(
        removed: (oldDocument) ->
          expect(oldDocument._id).toBe 'kvak'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('kvak')}"
          try
            result = HTTP.get(url)
            expect(result).toBeUndefined()
          catch e
            expect(e).toBeDefined()
          finally
            done()
      )
      testCollection4.remove({ _id: 'kvak', query: 'mnau' })

    it 'should not remove document from ES if transform function returns false', (done) ->
      options = optionsDefault
      options.collectionName = testCollection15
      transform = (doc) -> return false
      x = new Mongo2ES(options, transform)
      testCollection15.insert({ _id: 'kvak', query: 'mnau' })
      doc = testCollection15.findOne({ _id: 'kvak' })
      Mongo2ES::addToES(testCollection15, options.ES, doc)
      testCollection15.find().observe(
        removed: (oldDocument) ->
          expect(oldDocument._id).toBe 'kvak'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('kvak')}"
          try
            result = HTTP.get(url)
            expect(result).toBeDefined()
            expect(result.data._id).toBe('kvak')
          catch e
            expect(e).toBeUndefined()
          finally
            done()
      )
      testCollection15.remove({ _id: 'kvak', query: 'mnau' })

  describe 'stopWatch', ->
    it 'should stop watching the collection', (done) ->
      options = optionsDefault
      options.collectionName = testCollection5
      x = new Mongo2ES(options)
      watcher = x.stopWatch()
      expect(watcher._stopped).toBe true
      testCollection5.find().observe(
        added: (newDocument) ->
          expect(newDocument._id).toBe 'kvak'
          url = "#{x.options.ES.host}/#{x.options.ES.index}/#{x.options.ES.type}/#{encodeURI('kvak')}"
          try
            result = HTTP.get(url)
            expect(result).toBeUndefined()
          catch e
            expect(e).toBeDefined()
          finally
            done()
      )
      testCollection5.insert({ _id: 'kvak', query: 'mnau' })
