class ChatbotController < ApplicationController
    require 'tempfile'
    require 'rest-client'
    require 'json'
    PROMPTS = [
        '人名のみを抽出してください',
        '誕生日と思われる年月日をShort Date形式に変換して、値のみを出力してください',
        '電話番号のみを抽出してください',
        '依頼のタイトルのみを抽出してください',
        '依頼の概要を240字以内にまとめて、概要のみを出力してください',
        '依頼の日程と思われる年月日をShort Date形式に変換して、値のみを出力してください'
    ]

    def show
        profile = Profile.find(params[:id])
        render json: profile
    end

    def new
    end

    def create
        # 受け取ったカラム名と値
        column = params[:column]
        value = audio_to_text(params[:audio], params[:prompt_number].to_i)

        # セッションに一時的にデータを保持
        session[:profile_data] ||= {}
        session[:profile_data][column] = value
        Rails.logger.info("#{session[:profile_data]}")

        # 全てのデータが揃っているかチェック
        if session[:profile_data].keys.sort == %w[culumn1, culumn2, culumn3, culumn4, culumn5, culumn6]
            profile_params = convert_to_correct_types(session[:profile_data])

            @profile = Profile.new(profile_params)
            if @profile.save
                session.delete(:profile_data)
                render json: { message: 'Profile created successfully', profile: @profile }, status: :created
            else
                session.delete(:profile_data)
                render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
            end
        else
            render json: { response: value }
        end
    end

    # def create
    #     uploaded_file = params[:audio]
        
    #     # Whisperで音声ファイルをテキストに変換
    #     begin
    #         whisper_response = RestClient.post(
    #             'https://api.openai.com/v1/audio/transcriptions', 
    #             { 
    #                 model: 'whisper-1',
    #                 file: uploaded_file
    #             }, 
    #             { 
    #                 Authorization: "Bearer #{ENV['OPENAI_API_KEY']}"
    #             }
    #         )

    #         # 変換されたテキストを取得
    #         transcription = JSON.parse(whisper_response.body)
    #         if transcription
    #             Rails.logger.info("Recieved transcription: #{transcription}")
    #         end
    #         transcription_text = transcription["text"]

    #     rescue RestClient::ExceptionWithResponse => e
    #         puts "API request failed: #{e.response}"
    #         nil
    #     end
        
    #     begin
    #         # GPT-4で応答を生成
    #         gpt_response = RestClient.post(
    #             'https://api.openai.com/v1/chat/completions',
    #             {
    #                 model: "gpt-4",
    #                 messages: [
    #                     {
    #                         role: "system",
    #                         content: "You are a helpful assistant."
    #                     },
    #                     {
    #                         role: "user",
    #                         content: transcription_text
    #                     }
    #                 ],
    #                 max_tokens: 1000
    #             }.to_json,
    #             {
    #                 Authorization: "Bearer #{ENV['OPENAI_API_KEY']}",
    #                 Content_Type: "application/json"
    #             }
    #         )
    #     rescue RestClient::ExceptionWithResponse => e
    #         Rails.logger.error("RestClient Error: #{e.response}")
    #         render json: { error: "RestClient Error: #{e.response}" }, status: :bad_request
    #     end

    #     # GPT-4からの応答を取得
    #     puts(gpt_response)
    #     parsed_gpt_response = JSON.parse(gpt_response.body)
    #     response_text = parsed_gpt_response['choices'][0]['message']['content']

    #     # 応答を返す
    #     render json: { transcription: transcription_text, response: response_text }
    # end

    def audio_to_text(uploaded_file, prompt_number)
        prompt = PROMPTS[prompt_number]
        
        # Whisperで音声ファイルをテキストに変換
        begin
            whisper_response = RestClient.post(
                'https://api.openai.com/v1/audio/transcriptions', 
                { 
                    model: 'whisper-1',
                    file: uploaded_file
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
                            content: prompt
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
        return response_text
    end

    private

    # dataをそれぞれのカラムに適したデータ型に変換
    def convert_to_correct_types(data)
        {
            name: data['culumn1'],
            birthday: Date.parse(data['culumn2']),
            phone_number: data['culumn3'],
            request_title: data['culumn4'],
            request_description: data['culumn5'],
            request_schedule: Date.parse(data['culumn6'])
        }
    end
end
