# sms-reactor.ru integration for ruby
#
# Miguel Sanches
# rude.miguel@gmail.com

require 'net/http'
require 'json'
require 'date'

module SMSReactor

  # Exception indicating HTTP request error
  class HttpException < Exception
    attr_reader :http_response

    def initialize(msg=nil, http_response=nil)
      super(msg)
      @http_response = http_response
    end

  end

  # Excaption indicating server returned API errors
  class ApiError < Exception
  end

  # Main API class
  class Api

    # @param email [String] user email for auth
    # @param password [String] user password for auth
    def initialize( email, password )
      @url = "http://sms-reactor.ru/api/v1"
      @email = email
      @password = password
    end

    ### Signatures

    # Get signatures list
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [Array<Signature>] signatures array
    def get_signatures()
      exec_cmd( "signatures", :get )
    end

    # Submits new signature
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @param name [String] signature name
    def add_signature( name )
      exec_cmd( "signatures", :post, { :signature => { :name => name } } )
    end

    # Get signature status
    #
    # @param signature [Signature, Fixnum, #id] signature or signature id
    def get_signature( signature )
      id = signature.respond_to?( :id ) ? signature.id : signature.to_i
      exec_cmd( "signatures/#{ id }", :get )
    end

    ### Messages

    # Send message immediately
    #
    # @param text [String] message text
    # @param phone [String] destination phone number
    # @param signature_name [String] name of the approved signature
    # @param client_ident [String] client identifier of message (see API reference)
    # @param validity_period [Fixnum] message validity period in seconds (see API reference)
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [Message] sent message
    def send_message( text, phone, signature_name="TEST", client_ident=nil, validity_period=nil )
      exec_cmd( "messages", :post, { :message => { :text => text, :phone => phone, :signature_name => signature_name, :client_ident => client_ident, :validity_period => validity_period } } )
    end

    # Get message info
    #
    # @param message [Message, Fixnum, #id] message
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [Message] message
    def get_message( message )
      id = message.respond_to?( :id ) ? message.id : message.to_i
      exec_cmd( "messages/#{ id }", :get )
    end

    # Get message status
    #
    # @param message [Message, Fixnum, #id] message
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [Message] message with only status info
    def get_message_status( message )
      id = message.respond_to?( :id ) ? message.id : message.to_i
      exec_cmd( "messages/#{ id }/status", :get )
    end

    # Get number of message parts
    #
    # @param text [String] message text
    #
    # @return [Fixnum] number of parts
    def get_message_parts( text )
      exec_cmd( "messages/parts", :post, { :message => { :text => text } } ).parts
    end

    ### User

    # Get current user info
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [User] current user info
    def get_user()
      exec_cmd( "user", :get )
    end

    ### Mailings

    # Creates new mailing
    #
    # @param name [String] name of mailing
    # @param text [String] text of message
    # @param signature_name [String] name of message signature
    # @param scheduled_at [String, Time, #strftime] - date when to begin sending messages, when nil sends immediately
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [Mailing] mailing
    def create_mailing( name, text, signature_name, scheduled_at )
      scheduled_at = scheduled_at.strftime( "%Y-%m-%d %H:%M:%S" ) if scheduled_at.respond_to?(:strftime)
      exec_cmd( "mailings", :post, { :mailing => { :name => name, :text => text, :signature_name => signature_name, :scheduled_at => scheduled_at } } )
    end

    # Get mailing info
    #
    # @param mailing [Mailing, Fixnum, #id] - mailing or mailing id
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [Mailing] mailing
    def get_mailing( mailing )
      id = mailing.respond_to?( :id ) ? mailing.id : mailing.to_i
      exec_cmd( "mailings/#{ id }", :get )
    end

    # Get mailing status
    #
    # @param mailing [Mailing, Fixnum, #id] - mailing or mailing id
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [Mailing] mailing with only status
    def get_mailing_status( mailing )
      id = mailing.respond_to?( :id ) ? mailing.id : mailing.to_i
      exec_cmd( "mailings/#{ id }/status", :get )
    end  

    # Creates messages for mailing
    #
    # @param mailing [Mailing, Fixnum, #id] - mailing or mailing id
    # @param phones [String, Array<String>] list of phone numbers, string seperated by ',' or array of strings
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [Message] newly created message
    def add_mailing_phones( mailing, phones )
      id = mailing.respond_to?( :id ) ? mailing.id : mailing.to_i
      phones = phones.join(",") if phones.is_a?( Array )
      exec_cmd( "mailings/#{ id }/phones", :post, { :phones => phones } )    
    end

    # Get messages in mailing
    #
    # @param mailing [Mailing, Fixnum, #id] - mailing or mailing id
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [Array<Mailing>] araay of mailing messages
    def get_mailing_messages( mailing )
      id = mailing.respond_to?( :id ) ? mailing.id : mailing.to_i
      exec_cmd( "mailings/#{ id }/phones", :get )
    end

    # Start mailing
    #
    # @param mailing [Mailing, Fixnum, #id] - mailing or mailing id
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    def start_mailing( mailing )
      id = mailing.respond_to?( :id ) ? mailing.id : mailing.to_i
      exec_cmd( "mailings/#{ id }/start", :get )
    end

    # Stop mailing, mailing may be started again
    #
    # @param mailing [Mailing, Fixnum, #id] - mailing or mailing id
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    def stop_mailing( mailing )
      id = mailing.respond_to?( :id ) ? mailing.id : mailing.to_i
      exec_cmd( "mailings/#{ id }/stop", :get )
    end

    # Abort mailing, mailing can not be started again
    #
    # @param mailing [Mailing, Fixnum, #id] - mailing or mailing id
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    def abort_mailing( mailing )
      id = mailing.respond_to?( :id ) ? mailing.id : mailing.to_i
      exec_cmd( "mailings/#{ id }/abort", :get )
    end

  private

    # Executes API command
    #
    # @param url_part [String] relative API URL
    # @param method [Symbol, String] HTTP method
    # @param params [Hash] API parameters hash
    #
    # @raise [HttpException] on network or HTTP error 
    # @raise [ApiError] on API error
    #
    # @return [Object] result of API command
    def exec_cmd( url_part, method, params=nil )
      response_object = nil
      begin
        # requesting api
        response_text = http_request( "#{ @url }/#{ url_part }.json", method, params.to_json, @email, @password, { "Content-Type" => "application/json" } )
        # parse json text to hash
        response_hash = JSON.parse( response_text )
        # hash to struct
        response_object = json_to_object( response_hash ) 
      rescue JSON::JSONError => err
        raise RuntimeException, "JSON parse error while requesting #{ method } #{ url_part} : '#{ e.message }'"
      rescue HttpException => err
        if ( err.http_response.is_a?( Net::HTTPClientError ) )
          msg = "Unknown API error response while requesting #{ method } #{ url_part}: #{ err.http_response.body }"
          begin
            msg = JSON.parse( err.http_response.body ).to_ary.join(', ')
          rescue JSON::JSONError
          end
          raise ApiError, msg
        else
          raise
        end
      end
      response_object
    end

    # Translates json hash to ruby object
    #
    # @param json_hash [Hash, Array<Hash>] json hash
    #
    # @raise [RuntimeError] on usupported object type
    #
    # @return [Object, Array<Object>] ruby object
    def json_to_object( json_hash )
      r = nil
      if ( json_hash.is_a?( Array ) )
        r = []
        json_hash.each() do |array_entry|
          r << json_to_object( array_entry )
        end
      elsif ( json_hash.is_a?( Hash ) )
        # parsing time fields
        json_hash.each_pair() { |k,v| json_hash[k] = DateTime.strptime(v) if ( k.to_s.match(/_at/) && v ) }
        # converting hash to object
        k,v = json_hash.to_a.transpose
        r = Struct.new( *( k.map() { |kk| kk.to_sym } ) ).new( *v )
      else
        raise RuntimeError, "Unsupported type #{json_hash.class.to_s}"
      end
      r
    end

    # Performs http request, correctly handling HTTP redirects
    #
    # @param url [String] full URL to request
    # @param method [String, Symbol] HTTP request method can be ':get', ':post', ':put'
    # @param body [String] body for POST and PUT request, may be nil
    # @param user [String] user name for HTTP Basic Auth, may be nil
    # @param password [String] password for HTTP Basic Auth, may be nil
    # @param headers [Hash<Strting,String>] HTTP request headers hash
    #
    # @raise [HttpException] if network or http error occur
    #
    # @return [String] response body
    def http_request( url, method, body, user=nil, password=nil, headers={}, redirection_limit=10 )
      raise HttpException, "Redirection limit exceeded" if ( redirection_limit <= 0 )
      response = nil
      begin
        ourl = URI.parse( url )
        Timeout.timeout(10) do
          # prepare request
          doc = "#{ ourl.path }?#{ ourl.query }"
          doc = "/" if doc.empty?          
          request = case method.to_sym
            when :post
              Net::HTTP::Post.new( doc )
            when :get
              Net::HTTP::Get.new( doc )
            when :put
              Net::HTTP::Put.new( doc )
            else
              raise HttpException, "Unknown http method '#{method}'"
          end
          headers.each_pair() { |h,v| request.add_field( h, v ) }
          request.body = body unless body.to_s.empty?
          request.basic_auth( user, password ) if user
          request.use_ssl = true if ourl.instance_of?(URI::HTTPS)
          # executing
          response = Net::HTTP.new( ourl.host, ourl.port ).start { |http| http.request( request ) }
          # Анализируем ответ
          unless ( response.is_a?( Net::HTTPSuccess ) )
            if ( response.is_a?( Net::HTTPRedirection ) )
              return http_request( response['location'], body, redirection_limit - 1 )
            else
              raise HttpException.new( "Server error: #{response.class.to_s}", response )
            end
          end
        end        
      rescue Timeout::Error, EOFError, Errno::ENETUNREACH, Errno::EHOSTUNREACH, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::ECONNREFUSED, SocketError, URI::InvalidURIError => e
        raise HttpException, "#{e.message}, url=#{strURL}"
      end
      response.body
    end
  end

end