
noflo = require "noflo"
{ CouchDbComponentBase } = require "../lib/CouchDbComponentBase"

# ## Ports:
# 
# * In
#   * URL Inherited from CouchDbComponentBase parent class to receive connection information to CouchDB.
#     When a URL is received, the parent constructor will create an @dbConnection for us.
#   * IN  Created in this class to receive document IDs to look up in CouchDB.  The data contents on this
#     port should be simple strings.
#
# * Out
#   * LOG Inherited from LoggingComponent to send log messages for error handling.
#   * OUT Created in this class to send whole documents that were read from CouchDB.
#
# Use this component to read documents out of a CouchDB database.

class DeleteDocument extends CouchDbComponentBase
  constructor: ->
    super
    @pendingRequests = []

    @inPorts.in = new noflo.Port()
    @outPorts.out = new noflo.Port()

    # Add an event listener to the URL in-port that we inherit from CouchDbComponentBase
    @inPorts.url.on "data", (data) =>
      if @dbConnection?
        @deleteObject doc for doc in @pendingRequests
      else
        @sendLog
          logLevel: "error"
          context: "Connecting to the CouchDB database at URL '#{data}'."
          problem: "Parent class CouchDbComponentBase didn't set up a connection."
          solution: "Refer the document with this context information to the software developer."

    @inPorts.in.on "data", (docID) =>
      if @dbConnection?
        @deleteObject docID
      else
        @pendingRequests.push docID

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect()
      @outPorts.log.disconnect()

  deleteObject: (docID) ->
    @dbConnection.destroy docID, (err, document) =>
      if err?
        @sendLog
          logLevel: "error"
          context: "Reading document of ID #{docID} from CouchDB."
          problem: err
          solution: "Specify the correct document ID and check that another user/process did not delete the document."
      else
        @outPorts.out.send document if @outPorts.out.isAttached()

exports.getComponent = -> new DeleteDocument
