import net from "node:net";

export const Status = Object.freeze({
  PASS: "PASS",
  FAIL: "FAIL",
  SKIP: "SKIP",
});

export const envBool = (name, fallback) => {
  const value = process.env[name];
  if (value === undefined || value === "") return fallback;
  return ["1", "true", "yes", "on"].includes(value.toLowerCase());
};

export const waitForPort = (host, port, timeoutMs = 2000) =>
  new Promise((resolve) => {
    const deadline = Date.now() + timeoutMs;

    const attempt = () => {
      const socket = net.createConnection({ host, port });
      let finished = false;

      const finalize = (result) => {
        if (!finished) {
          finished = true;
          socket.destroy();
          resolve(result);
        }
      };

      socket.on("connect", () => finalize(true));
      socket.on("timeout", () => finalize(false));
      socket.on("error", () => finalize(false));
      socket.setTimeout(500);

      setTimeout(() => {
        if (finished) return;
        socket.destroy();
        if (Date.now() < deadline) {
          setTimeout(attempt, 200);
        } else {
          resolve(false);
        }
      }, 100);
    };

    attempt();
  });

export const gateCheck = async ({ service, client, envFlag, defaultEnabled, host, port }) => {
  if (!envBool(envFlag, defaultEnabled)) {
    return {
      service,
      client,
      status: Status.SKIP,
      detail: `${envFlag}=false -> skipped`,
    };
  }

  if (port && !(await waitForPort(host, port))) {
    return {
      service,
      client,
      status: Status.FAIL,
      detail: `${host}:${port} unreachable`,
    };
  }

  return null;
};
