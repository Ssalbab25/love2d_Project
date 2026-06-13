-- SoundManager.lua: 오디오 파일 합성 및 상황별 효과음 재생 매니저 클래스
-- SOLID: 
-- - SRP (단일 책임 원칙): WAV 파일의 기계적 바이트 합성 연산 및 사운드 버퍼 재생의 흐름 제어만 전담합니다.
-- - DIP (의존성 역전 원칙): 고수준 로직이 LÖVE2D 오디오 엔진 API에 직접 의존하여 직접 제어하지 않도록 추상화된 소리 재생 이벤트를 중계합니다.

local Object = require "libs.classic"
local config = require "src.config"

local SoundManager = Object:extend()

function SoundManager:new()
    self:generateWavs()
    
    if love and love.audio and love.audio.newSource then
        self.moveSound = love.audio.newSource("move.wav", "static")
        self.captureSound = love.audio.newSource("capture.wav", "static")
        self.checkSound = love.audio.newSource("check.wav", "static")
        self.checkmateSound = love.audio.newSource("checkmate.wav", "static")
    end
end

-- WAV 오디오 합성 로직
function SoundManager:generateWavs()
    local function file_exists(name)
        local f = io.open(name, "r")
        if f then f:close() return true end
        return false
    end
    
    local function to_int32_le(val)
        local b1 = val % 256
        local b2 = math.floor(val / 256) % 256
        local b3 = math.floor(val / 65536) % 256
        local b4 = math.floor(val / 16777216) % 256
        return string.char(b1, b2, b3, b4)
    end
    
    local function to_int16_le(val)
        local b1 = val % 256
        local b2 = math.floor(val / 256) % 256
        return string.char(b1, b2)
    end

    local function write_wav(filename, duration, sample_rate, wave_func)
        local num_samples = math.floor(duration * sample_rate)
        local data_size = num_samples
        local file_size = 36 + data_size
        
        local header = "RIFF" .. to_int32_le(file_size) .. "WAVE" .. "fmt " ..
                       to_int32_le(16) .. to_int16_le(1) .. to_int16_le(1) ..
                       to_int32_le(sample_rate) .. to_int32_le(sample_rate) ..
                       to_int16_le(1) .. to_int16_le(8) .. "data" .. to_int32_le(data_size)
        
        local data = {}
        for i = 1, num_samples do
            local t = (i - 1) / sample_rate
            local val = wave_func(t, duration)
            local byte_val = math.floor((val + 1) * 127.5 + 0.5)
            if byte_val < 0 then byte_val = 0 end
            if byte_val > 255 then byte_val = 255 end
            data[i] = string.char(byte_val)
        end
        
        local f = io.open(filename, "wb")
        if f then
            f:write(header)
            f:write(table.concat(data))
            f:close()
        end
    end
    
    if not file_exists("src/check.wav") then
        -- Check sound: A sharp high-pitched double warning beep (0.18s)
        write_wav("src/check.wav", 0.18, 11025, function(t, duration)
            local volume = 0.5
            local env = math.max(0, 1 - t/duration)
            if t > 0.07 and t < 0.11 then
                return 0
            end
            local freq = 1200
            return volume * env * math.sin(2 * math.pi * freq * t)
        end)
    end
    
    if not file_exists("src/checkmate.wav") then
        -- Checkmate sound: A descending, dramatic game over chime (0.6s)
        write_wav("src/checkmate.wav", 0.6, 11025, function(t, duration)
            local volume = 0.4
            local env = math.exp(-3 * t)
            local freq = 600 - (400 * (t / duration))
            local base = math.sin(2 * math.pi * freq * t)
            local sub = math.sin(2 * math.pi * (freq * 0.75) * t)
            local third = math.sin(2 * math.pi * (freq * 1.25) * t)
            return volume * env * (base + 0.4 * sub + 0.3 * third)
        end)
    end
end

-- 상황에 맞춘 효과음 재생
function SoundManager:playMoveSound(isGameOver, gameOverReason, isCapture, isInCheck)
    if config.isTesting then
        return
    end
    if not (self.moveSound and self.captureSound and self.checkSound and self.checkmateSound) then
        return
    end
    
    self.moveSound:stop()
    self.captureSound:stop()
    self.checkSound:stop()
    self.checkmateSound:stop()
    
    if isGameOver then
        if gameOverReason == "checkmate" then
            self.checkmateSound:play()
        else
            if isCapture then
                self.captureSound:play()
            else
                self.moveSound:play()
            end
        end
    else
        if isInCheck then
            self.checkSound:play()
        elseif isCapture then
            self.captureSound:play()
        else
            self.moveSound:play()
        end
    end
end

return SoundManager
