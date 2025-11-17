using eBooks.API.Auth;
using eBooks.Interfaces;
using eBooks.Models;
using eBooks.Models.Responses;
using eBooks.Models.Search;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eBooks.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class PurchasesController : BaseReadOnlyController<PurchasesSearch, PurchasesRes>
    {
        protected new IPurchasesService _service;

        public PurchasesController(IPurchasesService service)
            : base(service)
        {
            _service = service;
        }

        [Authorize(Policy = "Moderator")]
        public override async Task<PagedResult<PurchasesRes>> GetPaged([FromQuery] PurchasesSearch search)
        {
            return await base.GetPaged(search);
        }

        [Authorize(Policy = "Moderator")]
        public override async Task<PurchasesRes> GetById(int id)
        {
            return await base.GetById(id);
        }

        [Authorize(Policy = "User")]
        [HttpGet("{publisherId}/payment-history")]
        public async Task<PagedResult<PurchasesRes>> GetAllByPublisherId(int publisherId, [FromQuery] BaseSearch search)
        {
            return await _service.GetAllByPublisherId(publisherId, search);
        }
    }
}
