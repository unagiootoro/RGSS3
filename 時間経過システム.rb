=begin
  時間経過システム ver1.1
  byうなぎおおとろ(Twitter http://twitter.com/unagiootoro8388)

  歩くたびに時間が経過する古典的な時間経過システムを導入するスクリプトです。
  時間帯には、朝、昼、夕方、夜、深夜、夜明けを使用できます。

  [使用方法]
  時間の経過を許可するマップのメモ欄に、
  <時間経過マップ>
  と記述してください。
 
  夜専用BGMを流したいマップでは、
  <夜BGM:BGMファイル名>
  と記述することで、夜に専用BGMを流すことができます。
  例えば、インポートした"night-bgm.ogg"という夜専用BGMをセットしたい場合は、
  <夜BGM:night-bgm.ogg>
  となります。
 
  時間帯によって出現する敵グループを設定したい場合、
  敵グループ名に、
  <時間帯>敵グループ名
  と指定します。
  例えば、深夜にのみ、こうもり２匹を出現させたい場合、
  敵グループ名に、
  <深夜>こうもり*2
  となります。
=end


class Game_Map

  #ここからは設定です==============================================================

  #時間帯を管理する変数ID
  #変数の値
  #　　朝…0、昼…1、夕方…2、夜…3、深夜…4、夜明け…5
  Timezone_variable_id = 1

  def get_next_timezone_steps
    #各時間帯の長さ(単位：歩数)
    case now_timezone
    when Morning
      90 #朝の時間の長さ
    when Noon
      180 #昼の時間の長さ
    when Evening
      90 #夕方の時間の長さ
    when Night
      120 #夜の時間の長さ
    when LateNight
      120 #深夜の時間の長さ
    when Dawn
      120 #夜明けの時間の長さ
    end
  end

  #設定はここまでです==============================================================

  Morning = 0
  Noon = 1
  Evening = 2
  Night = 3
  LateNight = 4
  Dawn = 5

  alias advance_time__initialize initialize
  private :advance_time__initialize

  def initialize
    advance_time__initialize
    @last_timezone = now_timezone - 1
    @next_timezone_steps = get_next_timezone_steps
  end

  def now_timezone
    $game_variables[Timezone_variable_id]
  end

  def advance_time_map?
    @map.advance_time_map?
  end

  def change_timezone(timezone)
    $game_variables[Timezone_variable_id] = timezone
    case timezone
    when Morning
      $game_map.screen.start_tone_change(Tone.new(-34, -34, 0, 34), 60)
    when Noon
      $game_map.screen.start_tone_change(Tone.new(0, 0, 0, 0), 60)
    when Evening
      $game_map.screen.start_tone_change(Tone.new(68, -34, -34, 0), 60)
    when Night
      $game_map.screen.start_tone_change(Tone.new(-68, -68, 0, 68), 60)
    when LateNight
      $game_map.screen.start_tone_change(Tone.new(-136, -136, 0, 136), 60)
    when Dawn
      $game_map.screen.start_tone_change(Tone.new(-68, -68, 0, 68), 60)
    end
    @next_timezone_steps = get_next_timezone_steps
  end

  def advance_timezone
    if now_timezone < Dawn
      change_timezone(now_timezone + 1)
    else
      change_timezone(Morning)
    end
  end

  def advance_time
    @next_timezone_steps -= 1
    advance_timezone if @next_timezone_steps == 0
  end

  def autoplay
    if @map.autoplay_bgm
      bgm = if now_timezone >= Night && @map.night_bgm_name
        RPG::BGM.new(@map.night_bgm_name, @map.bgm.volume, @map.bgm.pitch)
      else
        @map.bgm
      end
      bgm.play
    end
    @map.bgs.play if @map.autoplay_bgs
  end
 
  def encounter_list
    @map.encounter_list.select do |encounter|
      if encounter.timezone
        if encounter.timezone == now_timezone
          true
        else
          false
        end
      else
        true
      end
    end
  end

end


class RPG::Map

  def advance_time_map?
    if @advance_time_map == nil
      if note =~ /^<時間経過マップ>/
        @advance_time_map = true
      else
        @advance_time_map = false
      end
    end
    @advance_time_map
  end

  def night_bgm_name
    if @night_bgm_name == nil
      if note =~ /^<夜BGM:(.+)>/m
        @night_bgm_name = $1.gsub(/[\r\n]/, "")
      else
        @night_bgm_name = false
      end
    end
    @night_bgm_name
  end

end


class Game_Player
  alias advance_time__increase_steps increase_steps
  private :advance_time__increase_steps

  def increase_steps
    advance_time__increase_steps
    $game_map.advance_time if $game_map.advance_time_map?
  end
end


class RPG::Map::Encounter
  def timezone
    if @timezone == nil
      @timezone = false
      if $data_troops[@troop_id].name =~ /^<(.+)>/
        @timezone = case $1
        when "朝"; 0
        when "昼"; 1
        when "夕方"; 2
        when "夜"; 3
        when "深夜"; 4
        when "夜明け"; 5
        end
      end
    end
    @timezone
  end
end
