/*
  ------------------------------------------------------------------------------------
  ClickUp API Client
  ------------------------------------------------------------------------------------
  Simple client for interacting with ClickUp API v2
  Based on: https://developer.clickup.com/reference/gettask
*/

const CLICKUP_API_BASE = 'https://api.clickup.com/api/v2'

export interface ClickUpClientOptions {
  apiKey: string
}

export class ClickUpClient {
  private apiKey: string

  constructor(options: ClickUpClientOptions) {
    this.apiKey = options.apiKey
  }

  async getTask(taskId: string): Promise<unknown> {
    const url = `${CLICKUP_API_BASE}/task/${taskId}`
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Authorization': this.apiKey,
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      const errorText = await response.text()
      let errorMessage = `HTTP ${response.status}: ${response.statusText}`
      try {
        const errorJson = JSON.parse(errorText)
        if (errorJson.err) {
          errorMessage = errorJson.err
        } else if (errorJson.message) {
          errorMessage = errorJson.message
        }
      } catch {
        // If parsing fails, use the raw error text if available
        if (errorText) {
          errorMessage = `${errorMessage} - ${errorText}`
        }
      }
      throw new Error(errorMessage)
    }

    return await response.json()
  }
}

