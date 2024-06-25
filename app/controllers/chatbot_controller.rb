class ChatbotController < ApplicationController
    require 'tempfile'
    require 'rest-client'
    require 'json'

    def new
    end

    def create
        uploaded_file = params[:audio]
        # file_path = Rails.root.join('public', 'test-audio.m4a')
        # uploaded_file = File.new(file_path, 'rb')

        # tempfile = Tempfile.new(['audio', '.webm'])
        # File.binwrite(tempfile.path, uploaded_file.read)
        # wavfile = Tempfile.new(['audio', '.wav'])
        # system("ffmpeg -i #{tempfile.path} -ar 16000 -ac 1 -c:a pcm_s16le #{wavfile.path}")


        # Whisperで音声ファイルをテキストに変換
        begin
            whisper_response = RestClient.post(
                'https://api.openai.com/v1/audio/transcriptions', 
                { 
                    model: 'whisper-1',
                    file: uploaded_file
                    # filename: uploaded_file.original_filename
                    # content_type: uploaded_file.content_type
                }, 
                { 
                    Authorization: "Bearer #{ENV['OPENAI_API_KEY']}"
                }
            )

            # 変換されたテキストを取得
            transcription = JSON.parse(whisper_response.body)
            if transcription
                Rails.logger.info("Recieved transcription: #{transcription}")
            end
            transcription_text = transcription["text"]

        rescue RestClient::ExceptionWithResponse => e
            puts "API request failed: #{e.response}"
            nil
        end
        
        begin
            # GPT-4で応答を生成
            gpt_response = RestClient.post(
                'https://api.openai.com/v1/chat/completions',
                {
                    model: "gpt-4",
                    messages: [
                        {
                            role: "system",
                            content: "You are a helpful assistant."
                        },
                        {
                            role: "user",
                            content: transcription_text
                        }
                    ],
                    max_tokens: 1000
                }.to_json,
                {
                    Authorization: "Bearer #{ENV['OPENAI_API_KEY']}",
                    Content_Type: "application/json"
                }
            )
        rescue RestClient::ExceptionWithResponse => e
            Rails.logger.error("RestClient Error: #{e.response}")
            render json: { error: "RestClient Error: #{e.response}" }, status: :bad_request
        end

        # GPT-4からの応答を取得
        puts(gpt_response)
        parsed_gpt_response = JSON.parse(gpt_response.body)
        response_text = parsed_gpt_response['choices'][0]['message']['content']

        # 応答を返す
        render json: { transcription: transcription_text, response: response_text }
    ensure
        # tempfile.close
        # tempfile.unlink
        # wavfile.close
        # wavfile.unlink
    end
end
