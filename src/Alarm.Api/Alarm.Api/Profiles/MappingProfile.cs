using Alarm.Api.Models.Alarm;
using Alarm.Api.Models.AlarmAction;
using Alarm.Api.Models.AlarmConnection;
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
        CreateMap<AlarmOnPush, AlarmDTO>();
        CreateMap<AlarmActionOnPush, AlarmActionEntity>()
            .ForMember(dest => dest.PartitionKey, opt => opt.MapFrom(src => src.UserId))
            .ForMember(dest => dest.RowKey, opt => opt.MapFrom(src => Guid.NewGuid().ToString()));

        CreateMap<UserDeviceOnUpsert, UserDeviceEntity>()
            .ForMember(dest => dest.UserId, opt => opt.MapFrom(src => src.UserId))
            .ForMember(dest => dest.DeviceToken, opt => opt.MapFrom(src => src.DeviceToken))
        ;
    }
}