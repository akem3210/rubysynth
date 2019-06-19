require_relative 'oscillator'
require_relative 'state_variable_filter'
require_relative 'adsr'
require_relative 'sound'
require_relative 'chorus'

class Monosynth < Sound
  def initialize(sfreq, preset={})
    super(sfreq, mode: :monophonic)
    @preset = {
      amp_attack: 0.02,
      amp_decay: 0.1,
      amp_sustain: 0.8,
      amp_release: 0.2,
      flt_attack: 0.01,
      flt_decay: 0.05,
      flt_sustain: 0.2,
      flt_release: 0.2,
      flt_envmod: 2000,
      flt_frequency: 500,
      flt_Q: 2,
      osc_waveform: :square,
      lfo_waveform: :sine,
      lfo_frequency: 2
    }.merge(preset)
    @oscillator = Oscillator.new(@sampling_frequency)
    @filter = StateVariableFilter.new(@sampling_frequency)
    @filter2 = StateVariableFilter.new(@sampling_frequency)
    @lfo = Oscillator.new(@sampling_frequency)
    @amp_env = Adsr.new(
      @preset[:amp_attack],
      @preset[:amp_decay],
      @preset[:amp_sustain],
      @preset[:amp_release]
    )
    @flt_env = Adsr.new(
      @preset[:flt_attack],
      @preset[:flt_decay],
      @preset[:flt_sustain],
      @preset[:flt_release]
    )
  end

  def run(offset)
    # time in seconds
    t = time(offset)
    events = active_events(t)
    if events.empty?
      0.0
    else
      event = events.last
      # lfo_out = (@lfo.run(@preset[:lfo_frequency], waveform: @preset[:lfo_waveform]) + 1) / 8 + 0.5
      osc_out = @oscillator.run(frequency(event[:note]), waveform: @preset[:osc_waveform])
      local_started = t - event[:started]
      local_stopped = event[:stopped] && event[:stopped] - event[:started]
      osc_out = @filter.run(osc_out, @preset[:flt_frequency] + @flt_env.run(local_started, local_stopped) * @preset[:flt_envmod], @preset[:flt_Q])
      # osc_out = @filter2.run(osc_out, @preset[:flt_frequency] + @flt_env.run(local_started, local_stopped) * @preset[:flt_envmod], @preset[:flt_Q])
      0.3 * osc_out * @amp_env.run(local_started, local_stopped)
    end
  end
end
