using Alarm.Api.Models.Alarm;
using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Alarm.Api.Profiles;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<AlarmOnCreate, AlarmEntity>()
            .ForMember(dest => dest.MindrUserId, opt => opt.MapFrom(src => src.MindrUserId))
            .ForMember(dest => dest.MindrConnectionId, opt => opt.MapFrom(src => src.MindrConnectionId))
            .ForMember(dest => dest.Time, opt => opt.MapFrom(src => src.Time))
            .ForMember(dest => dest.ScheduledDays, opt => opt.MapFrom(src => src.ScheduledDays != null ? string.Join(",", src.ScheduledDays) : ""))
            .ForMember(dest => dest.Label, opt => opt.MapFrom(src => src.Label))
            .ForMember(dest => dest.Sound, opt => opt.MapFrom(src => src.Sound))
            .ForMember(dest => dest.IsEnabled, opt => opt.MapFrom(src => src.IsEnabled))
            .ForMember(dest => dest.UseVibration, opt => opt.MapFrom(src => src.UseVibration))
        ;

        CreateMap<AlarmOnUpdate, AlarmEntity>()
            .ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.Id))
            .ForMember(dest => dest.MindrUserId, opt => opt.MapFrom(src => src.MindrUserId))
            .ForMember(dest => dest.MindrConnectionId, opt => opt.MapFrom(src => src.MindrConnectionId))
            .ForMember(dest => dest.Time, opt => opt.MapFrom(src => src.Time))
            .ForMember(dest => dest.ScheduledDays, opt => opt.MapFrom(src => src.ScheduledDays != null ? string.Join(",", src.ScheduledDays) : ""))
            .ForMember(dest => dest.Label, opt => opt.MapFrom(src => src.Label))
            .ForMember(dest => dest.Sound, opt => opt.MapFrom(src => src.Sound))
            .ForMember(dest => dest.IsEnabled, opt => opt.MapFrom(src => src.IsEnabled))
            .ForMember(dest => dest.UseVibration, opt => opt.MapFrom(src => src.UseVibration))
        ;
    }
}