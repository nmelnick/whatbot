module Whatbot
	class Message
		@is_direct = false

		attr_accessor :from,
					  :to,
					  :reply_to,
					  :content,
					  :timestamp,
					  :is_direct,
					  :me,
					  :origin,
					  :invisible

		def initialize(options = {})
			options.each { |k,v| self.send("#{k}=", v) }
			_determine_me()
		end

		def is_private()
			return ( @me ? ( @to == @me ) : false )
		end

		def check_content(content)
			content.sub( /^\s+/, '' )
			content.sub( /\s+$/, '' )
			@content = content
		end

		def reply(overrides = {})
			message = Message.new({
				'from'	=> @me,
				'to'	  => ( @reply_to || ( is_private ? @from : @to ) ),
				'me'	  => @me,
				'content' => ''
			})
			overrides.each { |k,v| message.send("#{k}=", v) }
		end

		# Determine if the message is talking about me
		def _determine_me()
			if @me
				content = nil
				if @content =~ /, ?$me[\?\!\. ]*?$/i
					content = @content
					content.sub( /, ?$me[\?\!\. ]*?$/i, '' );
				elsif @content =~ /^$me[\:\,\- ]+/i
					content = @content
					content.sub( /^$me[\:\,\- ]+/i, '' );
				elsif @content =~ /^$me \-+ /i
					content = @content
					content.sub( /^$me \-+ /i, '' );
				end
				if content != nil
					@content = content
					@is_direct = true
				end
			end

			if is_private
				@is_direct = true
			end
		end
	end
end

