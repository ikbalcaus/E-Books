using eBooks.API.Auth;
using eBooks.Interfaces;
using eBooks.Models.Requests;
using eBooks.Models.Responses;
using eBooks.Models.Search;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eBooks.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : BaseCRUDController<UsersSearch, UsersPostReq, UsersPutReq, UsersRes>
    {
        protected new IUsersService _service;
        protected AccessControlHandler _accessControlHandler;

        public UsersController(IUsersService service, AccessControlHandler accessControlHandler)
            : base(service)
        {
            _service = service;
            _accessControlHandler = accessControlHandler;
        }

        [AllowAnonymous]
        public override async Task<PagedResult<UsersRes>> GetPaged([FromQuery] UsersSearch search)
        {
            return await base.GetPaged(search);
        }

        [AllowAnonymous]
        public override async Task<UsersRes> GetById(int id)
        {
            return await base.GetById(id);
        }

        [AllowAnonymous]
        public override async Task<UsersRes> Post(UsersPostReq req)
        {
            return await base.Post(req);
        }

        [Authorize(Policy = "User")]
        public override async Task<UsersRes> Put(int id, [FromForm] UsersPutReq req)
        {
            await _accessControlHandler.CheckIsOwnerByUserId(id);
            return await base.Put(id, req);
        }

        [Authorize(Policy = "User")]
        public override async Task<UsersRes> Delete(int id)
        {
            await _accessControlHandler.CheckIsOwnerByUserId(id);
            return await base.Delete(id);
        }

        [Authorize(Policy = "Admin")]
        [HttpDelete("{id}/admin-delete")]
        public async Task<UsersRes> DeleteByAdmin(int id, string? reason)
        {
            return await _service.DeleteByAdmin(id, reason);
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<LoginRes> Login(LoginReq req)
        {
            return await _service.Login(req);
        }

        [AllowAnonymous]
        [HttpPatch("forgot-password")]
        public async Task<UsersRes> ForgotPassword(string email)
        {
            return await _service.ForgotPassword(email);
        }

        [AllowAnonymous]
        [HttpPatch("reset-password")]
        public async Task<UsersRes> ResetPassword(string token, string password)
        {
            return await _service.ResetPassword(token, password);
        }

        [Authorize(Policy = "User")]
        [HttpPatch("{id}/verify-email")]
        public async Task<UsersRes> VerifyEmail(int id, [FromQuery] string? token = null)
        {
            await _accessControlHandler.CheckIsOwnerByUserId(id);
            return await _service.VerifyEmail(id, token);
        }

        [Authorize(Policy = "Admin")]
        [HttpPatch("{id}/verify-publisher")]
        public async Task<UsersRes> VerifyPublisher(int id)
        {
            return await _service.VerifyPublisher(id);
        }
    }
}
