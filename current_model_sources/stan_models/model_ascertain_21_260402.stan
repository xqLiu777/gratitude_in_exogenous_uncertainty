data {
  int<lower=1> N;                           // 总观测数
  int<lower=1> S;                           // 被试数
  array[N] int<lower=1, upper=S> subject;   // 被试ID
  vector[N] x;                              // 自变量（必须已标准化：均值0，标准差1）
  vector[N] y;                              // 因变量（范围-50-50）
}

parameters {
  // 群体水平参数 - 分两侧
  real mu_int;                        // 截距群体均值
  real mu_int_bias;                   // x < 0时截距bias
  real mu_slo;                    // x<0侧的斜率群体均值
  
  // 群体水平标准差 - 分两侧
  real<lower=0> sigma_int;
  real<lower=0> sigma_int_bias;
  real<lower=0> sigma_slo;
  
  // ---- 非中心参数化的核心 ----
  // 个体参数扰动项 - 分两侧
  vector[S] z_int;               // 的个体截距扰动
  vector[S] z_int_bias;
  vector[S] z_slo;                // x<0侧的个体斜率扰动
  
  real<lower=0> sigma_obs;        
  real<lower=2> nu;
  
  // 【新增】：产生精确 0 值的概率
  // real<lower=0, upper=1> theta;
}


transformed parameters {
  // 非中心参数化转换：将标准正态变量转换为实际个体参数
  vector[S] inter = mu_int + sigma_int * z_int;
  vector[S] inter_bias = mu_int_bias + sigma_int_bias * z_int_bias;
  vector[S] slo = mu_slo + sigma_slo * z_slo;

}

model {
  /* ---------- 群体水平先验 ---------- */
  // 截距先验 - 分两侧
  mu_int ~ normal(0, 50);        // 根据y尺度调整
  mu_int_bias ~ normal(0, 50);        // 根据y尺度调整
  // 斜率先验 - 分两侧
  mu_slo ~ normal(0, 15);          // x已标准化
  
  /* ---------- 变异参数先验 ---------- */
  // 群体层标准差 - 分两侧
  sigma_int ~ normal(0, 15);
  sigma_int_bias ~ normal(0, 15);       // 根据y尺度调整
  sigma_slo ~ normal(0, 15);
  sigma_obs ~ normal(0, 15);
  
  /* ---------- 个体水平先验 ---------- */
  // 非中心参数化先验 - 分两侧
  z_int ~ std_normal();
  z_int_bias ~ std_normal();
  z_slo ~ std_normal();
  
  // 自由度先验保持不变，因为它与 y 的量级无关
  nu ~ gamma(2, 0.1);
  
  // theta 的先验：beta(1, 1) 代表 0~1 之间的均匀分布
  // theta ~ beta(1, 1);
  
  {
    // 在局部环境 {} 里计算 mu，算完即焚，不占内存
    vector[N] mu;
    for (n in 1:N) {
      int s = subject[n];
      if (x[n] < 0) {
        mu[n] = slo[s] * x[n] - inter[s] + inter_bias[s];
      } else {
        mu[n] = slo[s] * x[n] + inter[s];
      }
    }
    // 所有人，不管是不是 0，全部公平地服从这个厚尾分布
    target += student_t_lpdf(y | nu, mu, sigma_obs);
  }

}

generated quantities {
  // ---------- 1. 后验预测值 ----------
  vector[N] y_rep;
  // ---------- 2. 逐点对数似然（loo包必需） ---------- 
  vector[N] log_lik;
  
  {
    real mu_gen;
    for (n in 1:N) {
      int s = subject[n];
      
      // 根据 x 的正负，套用不同的参数
      if (x[n] < 0) {
        mu_gen = slo[s] * x[n] - inter[s] + inter_bias[s];
      } else {
        mu_gen = slo[s] * x[n] + inter[s];
      }
      
      // 生成似然值和预测值
      log_lik[n] = student_t_lpdf(y[n] | nu, mu_gen, sigma_obs);
      y_rep[n] = student_t_rng(nu, mu_gen, sigma_obs);
    }
  }

}
