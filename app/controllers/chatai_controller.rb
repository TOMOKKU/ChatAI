class ChataiController < ApplicationController
    require 'rest-client'
    require 'json'

    def new
    end

    def create
        text = params[:message]
        if text
            Rails.logger.info("Your Message: #{text}")
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
                            content: text
                        }
                    ],
                    max_tokens: 150
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
        render json: {gpt_response: response_text}
        # if gpt_response
        #     Rails.logger.info("Recieved: #{gpt_response}")
        # end

        # # 応答を返す
        # render json: { response: gpt_response }
    end
end
